// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.error;

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart' show AstNode;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart' show ScannerErrorCode;
import 'package:analyzer/src/generated/generated/shared_messages.dart'
    as shared_messages;
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/model.dart';
import 'package:analyzer/task/model.dart';
import 'package:source_span/source_span.dart';

/**
 * The descriptor used to associate error processors with analysis contexts in
 * configuration data.
 */
final ListResultDescriptor<ErrorProcessor> CONFIGURED_ERROR_PROCESSORS =
    new ListResultDescriptorImpl('configured.errors', const <ErrorProcessor>[]);

/**
 * An error discovered during the analysis of some Dart code.
 *
 * See [AnalysisErrorListener].
 */
class AnalysisError {
  /**
   * An empty array of errors used when no errors are expected.
   */
  static const List<AnalysisError> NO_ERRORS = const <AnalysisError>[];

  /**
   * A [Comparator] that sorts by the name of the file that the [AnalysisError]
   * was found.
   */
  static Comparator<AnalysisError> FILE_COMPARATOR =
      (AnalysisError o1, AnalysisError o2) =>
          o1.source.shortName.compareTo(o2.source.shortName);

  /**
   * A [Comparator] that sorts error codes first by their severity (errors
   * first, warnings second), and then by the error code type.
   */
  static Comparator<AnalysisError> ERROR_CODE_COMPARATOR =
      (AnalysisError o1, AnalysisError o2) {
    ErrorCode errorCode1 = o1.errorCode;
    ErrorCode errorCode2 = o2.errorCode;
    ErrorSeverity errorSeverity1 = errorCode1.errorSeverity;
    ErrorSeverity errorSeverity2 = errorCode2.errorSeverity;
    if (errorSeverity1 == errorSeverity2) {
      ErrorType errorType1 = errorCode1.type;
      ErrorType errorType2 = errorCode2.type;
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
   * The correction to be displayed for this error, or `null` if there is no
   * correction information for this error.
   */
  String _correction;

  /**
   * The source in which the error occurred, or `null` if unknown.
   */
  final Source source;

  /**
   * The character offset from the beginning of the source (zero based) where
   * the error occurred.
   */
  int offset = 0;

  /**
   * The number of characters from the offset to the end of the source which
   * encompasses the compilation error.
   */
  int length = 0;

  /**
   * A flag indicating whether this error can be shown to be a non-issue because
   * of the result of type propagation.
   */
  bool isStaticOnly = false;

  /**
   * Initialize a newly created analysis error. The error is associated with the
   * given [source] and is located at the given [offset] with the given
   * [length]. The error will have the given [errorCode] and the list of
   * [arguments] will be used to complete the message.
   */
  AnalysisError(this.source, this.offset, this.length, this.errorCode,
      [List<Object> arguments]) {
    this._message = formatList(errorCode.message, arguments);
    String correctionTemplate = errorCode.correction;
    if (correctionTemplate != null) {
      this._correction = formatList(correctionTemplate, arguments);
    }
  }

  /**
   * Initialize a newly created analysis error with given values.
   */
  AnalysisError.forValues(this.source, this.offset, this.length, this.errorCode,
      this._message, this._correction);

  /**
   * Return the template used to create the correction to be displayed for this
   * error, or `null` if there is no correction information for this error. The
   * correction should indicate how the user can fix the error.
   */
  String get correction => _correction;

  @override
  int get hashCode {
    int hashCode = offset;
    hashCode ^= (_message != null) ? _message.hashCode : 0;
    hashCode ^= (source != null) ? source.hashCode : 0;
    return hashCode;
  }

  /**
   * Return the message to be displayed for this error. The message should
   * indicate what is wrong and why it is wrong.
   */
  String get message => _message;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    // prepare other AnalysisError
    if (other is AnalysisError) {
      // Quick checks.
      if (!identical(errorCode, other.errorCode)) {
        return false;
      }
      if (offset != other.offset || length != other.length) {
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
    return false;
  }

  /**
   * Return the value of the given [property], or `null` if the given property
   * is not defined for this error.
   */
  Object/*=V*/ getProperty/*<V>*/(ErrorProperty/*<V>*/ property) => null;

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write((source != null) ? source.fullName : "<unknown source>");
    buffer.write("(");
    buffer.write(offset);
    buffer.write("..");
    buffer.write(offset + length - 1);
    buffer.write("): ");
    //buffer.write("(" + lineNumber + ":" + columnNumber + "): ");
    buffer.write(_message);
    return buffer.toString();
  }

  /**
   * Merge all of the errors in the lists in the given list of [errorLists] into
   * a single list of errors.
   */
  static List<AnalysisError> mergeLists(List<List<AnalysisError>> errorLists) {
    Set<AnalysisError> errors = new HashSet<AnalysisError>();
    for (List<AnalysisError> errorList in errorLists) {
      errors.addAll(errorList);
    }
    return errors.toList();
  }
}

/**
 * An object that listen for [AnalysisError]s being produced by the analysis
 * engine.
 */
abstract class AnalysisErrorListener {
  /**
   * An error listener that ignores errors that are reported to it.
   */
  static final AnalysisErrorListener NULL_LISTENER =
      new AnalysisErrorListener_NULL_LISTENER();

  /**
   * This method is invoked when an [error] has been found by the analysis
   * engine.
   */
  void onError(AnalysisError error);
}

/**
 * An [AnalysisErrorListener] that ignores error.
 */
class AnalysisErrorListener_NULL_LISTENER implements AnalysisErrorListener {
  @override
  void onError(AnalysisError event) {
    // Ignore errors
  }
}

/**
 * An [AnalysisError] that can have arbitrary properties associated with it.
 */
class AnalysisErrorWithProperties extends AnalysisError {
  /**
   * The properties associated with this error.
   */
  HashMap<ErrorProperty, Object> _propertyMap =
      new HashMap<ErrorProperty, Object>();

  /**
   * Initialize a newly created analysis error. The error is associated with the
   * given [source] and is located at the given [offset] with the given
   * [length]. The error will have the given [errorCode] and the list of
   * [arguments] will be used to complete the message.
   */
  AnalysisErrorWithProperties(
      Source source, int offset, int length, ErrorCode errorCode,
      [List<Object> arguments])
      : super(source, offset, length, errorCode, arguments);

  @override
  Object/*=V*/ getProperty/*<V>*/(ErrorProperty/*<V>*/ property) =>
      _propertyMap[property] as Object/*=V*/;

  /**
   * Set the value of the given [property] to the given [value]. Using a value
   * of `null` will effectively remove the property from this error.
   */
  void setProperty/*<V>*/(ErrorProperty/*<V>*/ property, Object/*=V*/ value) {
    _propertyMap[property] = value;
  }
}

/**
 * The error codes used for errors in analysis options files. The convention for
 * this class is for the name of the error code to indicate the problem that
 * caused the error to be generated and for the error message to explain what is
 * wrong and, when appropriate, how the problem can be corrected.
 */
class AnalysisOptionsErrorCode extends ErrorCode {
  /**
   * An error code indicating that there is a syntactic error in the file.
   *
   * Parameters:
   * 0: the error message from the parse error
   */
  static const AnalysisOptionsErrorCode PARSE_ERROR =
      const AnalysisOptionsErrorCode('PARSE_ERROR', '{0}');

  /**
   * Initialize a newly created error code to have the given [name].
   */
  const AnalysisOptionsErrorCode(String name, String message,
      [String correction])
      : super(name, message, correction);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType.COMPILE_TIME_ERROR;
}

/**
 * The error codes used for warnings in analysis options files. The convention
 * for this class is for the name of the error code to indicate the problem that
 * caused the error to be generated and for the error message to explain what is
 * wrong and, when appropriate, how the problem can be corrected.
 */
class AnalysisOptionsWarningCode extends ErrorCode {
  /**
   * An error code indicating that a plugin is being configured with an
   * unsupported option and legal options are provided.
   *
   * Parameters:
   * 0: the plugin name
   * 1: the unsupported option key
   * 2: legal values
   */
  static const AnalysisOptionsWarningCode UNSUPPORTED_OPTION_WITH_LEGAL_VALUES =
      const AnalysisOptionsWarningCode('UNSUPPORTED_OPTION_WITH_LEGAL_VALUES',
          "The option '{1}' is not supported by {0}, supported values are {2}");

  /**
   * An error code indicating that a plugin is being configured with an
   * unsupported option where there is just one legal value.
   *
   * Parameters:
   * 0: the plugin name
   * 1: the unsupported option key
   * 2: the legal value
   */
  static const AnalysisOptionsWarningCode UNSUPPORTED_OPTION_WITH_LEGAL_VALUE =
      const AnalysisOptionsWarningCode('UNSUPPORTED_OPTION_WITH_LEGAL_VALUE',
          "The option '{1}' is not supported by {0}, did you mean {2}?");

  /**
   * An error code indicating that an option entry is being configured with an
   * unsupported value.
   *
   * Parameters:
   * 0: the option name
   * 1: the unsupported value
   * 2: legal values
   */
  static const AnalysisOptionsWarningCode UNSUPPORTED_VALUE =
      const AnalysisOptionsWarningCode('UNSUPPORTED_VALUE',
          "The value '{1}' is not supported by {0}, legal values are {2}");

  /**
   * An error code indicating that an unrecognized error code is being used to
   * specify an error filter.
   *
   * Parameters:
   * 0: the unrecognized error code
   */
  static const AnalysisOptionsWarningCode UNRECOGNIZED_ERROR_CODE =
      const AnalysisOptionsWarningCode(
          'UNRECOGNIZED_ERROR_CODE', "'{0}' is not a recognized error code");

  /**
   * Initialize a newly created warning code to have the given [name].
   */
  const AnalysisOptionsWarningCode(String name, String message,
      [String correction])
      : super(name, message, correction);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.WARNING;

  @override
  ErrorType get type => ErrorType.STATIC_WARNING;
}

/**
 * An [AnalysisErrorListener] that keeps track of whether any error has been
 * reported to it.
 */
class BooleanErrorListener implements AnalysisErrorListener {
  /**
   * A flag indicating whether an error has been reported to this listener.
   */
  bool _errorReported = false;

  /**
   * Return `true` if an error has been reported to this listener.
   */
  bool get errorReported => _errorReported;

  @override
  void onError(AnalysisError error) {
    _errorReported = true;
  }
}

/**
 * The error codes used for compile time errors caused by constant evaluation
 * that would throw an exception when run in checked mode. The client of the
 * analysis engine is responsible for determining how these errors should be
 * presented to the user (for example, a command-line compiler might elect to
 * treat these errors differently depending whether it is compiling it "checked"
 * mode).
 */
class CheckedModeCompileTimeErrorCode extends ErrorCode {
  // TODO(paulberry): improve the text of these error messages so that it's
  // clear to the user that the error is coming from constant evaluation (and
  // hence the constant needs to be a subtype of the annotated type) as opposed
  // to static type analysis (which only requires that the two types be
  // assignable).  Also consider populating the "correction" field for these
  // errors.

  /**
   * 12.11.2 Const: It is a compile-time error if evaluation of a constant
   * object results in an uncaught exception being thrown.
   */
  static const CheckedModeCompileTimeErrorCode
      CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH =
      const CheckedModeCompileTimeErrorCode(
          'CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH',
          "The object type '{0}' cannot be assigned to the field '{1}', which has type '{2}'");

  /**
   * 12.11.2 Const: It is a compile-time error if evaluation of a constant
   * object results in an uncaught exception being thrown.
   */
  static const CheckedModeCompileTimeErrorCode
      CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH =
      const CheckedModeCompileTimeErrorCode(
          'CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH',
          "The object type '{0}' cannot be assigned to a parameter of type '{1}'");

  /**
   * 7.6.1 Generative Constructors: In checked mode, it is a dynamic type error
   * if o is not <b>null</b> and the interface of the class of <i>o</i> is not a
   * subtype of the static type of the field <i>v</i>.
   *
   * 12.11.2 Const: It is a compile-time error if evaluation of a constant
   * object results in an uncaught exception being thrown.
   *
   * Parameters:
   * 0: the name of the type of the initializer expression
   * 1: the name of the type of the field
   */
  static const CheckedModeCompileTimeErrorCode
      CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE =
      const CheckedModeCompileTimeErrorCode(
          'CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE',
          "The initializer type '{0}' cannot be assigned to the field type '{1}'");

  /**
   * 12.6 Lists: A run-time list literal &lt;<i>E</i>&gt; [<i>e<sub>1</sub></i>
   * ... <i>e<sub>n</sub></i>] is evaluated as follows:
   * * The operator []= is invoked on <i>a</i> with first argument <i>i</i> and
   *   second argument <i>o<sub>i+1</sub></i><i>, 1 &lt;= i &lt;= n</i>
   *
   * 12.14.2 Binding Actuals to Formals: Let <i>T<sub>i</sub></i> be the static
   * type of <i>a<sub>i</sub></i>, let <i>S<sub>i</sub></i> be the type of
   * <i>p<sub>i</sub>, 1 &lt;= i &lt;= n+k</i> and let <i>S<sub>q</sub></i> be
   * the type of the named parameter <i>q</i> of <i>f</i>. It is a static
   * warning if <i>T<sub>j</sub></i> may not be assigned to <i>S<sub>j</sub>,
   * 1 &lt;= j &lt;= m</i>.
   */
  static const CheckedModeCompileTimeErrorCode
      LIST_ELEMENT_TYPE_NOT_ASSIGNABLE = const CheckedModeCompileTimeErrorCode(
          'LIST_ELEMENT_TYPE_NOT_ASSIGNABLE',
          "The element type '{0}' cannot be assigned to the list type '{1}'");

  /**
   * 12.7 Map: A run-time map literal &lt;<i>K</i>, <i>V</i>&gt;
   * [<i>k<sub>1</sub></i> : <i>e<sub>1</sub></i> ... <i>k<sub>n</sub></i> :
   * <i>e<sub>n</sub></i>] is evaluated as follows:
   * * The operator []= is invoked on <i>m</i> with first argument
   *   <i>k<sub>i</sub></i> and second argument <i>e<sub>i</sub></i><i>, 1 &lt;=
   *   i &lt;= n</i>
   *
   * 12.14.2 Binding Actuals to Formals: Let <i>T<sub>i</sub></i> be the static
   * type of <i>a<sub>i</sub></i>, let <i>S<sub>i</sub></i> be the type of
   * <i>p<sub>i</sub>, 1 &lt;= i &lt;= n+k</i> and let <i>S<sub>q</sub></i> be
   * the type of the named parameter <i>q</i> of <i>f</i>. It is a static
   * warning if <i>T<sub>j</sub></i> may not be assigned to <i>S<sub>j</sub>, 1
   * &lt;= j &lt;= m</i>.
   */
  static const CheckedModeCompileTimeErrorCode MAP_KEY_TYPE_NOT_ASSIGNABLE =
      const CheckedModeCompileTimeErrorCode('MAP_KEY_TYPE_NOT_ASSIGNABLE',
          "The element type '{0}' cannot be assigned to the map key type '{1}'");

  /**
   * 12.7 Map: A run-time map literal &lt;<i>K</i>, <i>V</i>&gt;
   * [<i>k<sub>1</sub></i> : <i>e<sub>1</sub></i> ... <i>k<sub>n</sub></i> :
   * <i>e<sub>n</sub></i>] is evaluated as follows:
   * * The operator []= is invoked on <i>m</i> with first argument
   *   <i>k<sub>i</sub></i> and second argument <i>e<sub>i</sub></i><i>, 1 &lt;=
   *   i &lt;= n</i>
   *
   * 12.14.2 Binding Actuals to Formals: Let <i>T<sub>i</sub></i> be the static
   * type of <i>a<sub>i</sub></i>, let <i>S<sub>i</sub></i> be the type of
   * <i>p<sub>i</sub>, 1 &lt;= i &lt;= n+k</i> and let <i>S<sub>q</sub></i> be
   * the type of the named parameter <i>q</i> of <i>f</i>. It is a static
   * warning if <i>T<sub>j</sub></i> may not be assigned to <i>S<sub>j</sub>, 1
   * &lt;= j &lt;= m</i>.
   */
  static const CheckedModeCompileTimeErrorCode MAP_VALUE_TYPE_NOT_ASSIGNABLE =
      const CheckedModeCompileTimeErrorCode('MAP_VALUE_TYPE_NOT_ASSIGNABLE',
          "The element type '{0}' cannot be assigned to the map value type '{1}'");

  /**
   * 12.11.2 Const: It is a compile-time error if evaluation of a constant
   * object results in an uncaught exception being thrown.
   */
  static const CheckedModeCompileTimeErrorCode VARIABLE_TYPE_MISMATCH =
      const CheckedModeCompileTimeErrorCode('VARIABLE_TYPE_MISMATCH',
          "The object type '{0}' cannot be assigned to a variable of type '{1}'");

  /**
   * Initialize a newly created error code to have the given [name]. The message
   * associated with the error will be created from the given [message]
   * template. The correction associated with the error will be created from the
   * given [correction] template.
   */
  const CheckedModeCompileTimeErrorCode(String name, String message,
      [String correction])
      : super(name, message, correction);

  @override
  ErrorSeverity get errorSeverity =>
      ErrorType.CHECKED_MODE_COMPILE_TIME_ERROR.severity;

  @override
  ErrorType get type => ErrorType.CHECKED_MODE_COMPILE_TIME_ERROR;
}

/**
 * The error codes used for compile time errors. The convention for this class
 * is for the name of the error code to indicate the problem that caused the
 * error to be generated and for the error message to explain what is wrong and,
 * when appropriate, how the problem can be corrected.
 */
class CompileTimeErrorCode extends ErrorCode {
  /**
   * Enum proposal: It is also a compile-time error to explicitly instantiate an
   * enum via 'new' or 'const' or to access its private fields.
   */
  static const CompileTimeErrorCode ACCESS_PRIVATE_ENUM_FIELD =
      const CompileTimeErrorCode('ACCESS_PRIVATE_ENUM_FIELD',
          "The private fields of an enum cannot be accessed, even within the same library");

  /**
   * 14.2 Exports: It is a compile-time error if a name <i>N</i> is re-exported
   * by a library <i>L</i> and <i>N</i> is introduced into the export namespace
   * of <i>L</i> by more than one export, unless each all exports refer to same
   * declaration for the name N.
   *
   * Parameters:
   * 0: the name of the ambiguous element
   * 1: the name of the first library that the type is found
   * 2: the name of the second library that the type is found
   */
  static const CompileTimeErrorCode AMBIGUOUS_EXPORT =
      const CompileTimeErrorCode('AMBIGUOUS_EXPORT',
          "The name '{0}' is defined in the libraries '{1}' and '{2}'");

  /**
   * 15 Metadata: The constant expression given in an annotation is type checked
   * and evaluated in the scope surrounding the declaration being annotated.
   *
   * 12.11.2 Const: It is a compile-time error if <i>T</i> is not a class
   * accessible in the current scope, optionally followed by type arguments.
   *
   * 12.11.2 Const: If <i>e</i> is of the form <i>const T.id(a<sub>1</sub>,
   * &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;
   * x<sub>n+k</sub>: a<sub>n+k</sub>)</i> it is a compile-time error if
   * <i>T</i> is not a class accessible in the current scope, optionally
   * followed by type arguments.
   *
   * Parameters:
   * 0: the name of the non-type element
   */
  static const CompileTimeErrorCode ANNOTATION_WITH_NON_CLASS =
      const CompileTimeErrorCode(
          'ANNOTATION_WITH_NON_CLASS', "The name '{0}' is not a class");

  /**
   * 12.33 Argument Definition Test: It is a compile time error if <i>v</i> does
   * not denote a formal parameter.
   *
   * Parameters:
   * 0: the name of the identifier in the argument definition test that is not a
   *    parameter
   */
  static const CompileTimeErrorCode ARGUMENT_DEFINITION_TEST_NON_PARAMETER =
      const CompileTimeErrorCode(
          'ARGUMENT_DEFINITION_TEST_NON_PARAMETER', "'{0}' is not a parameter");

  /**
   * ?? Asynchronous For-in: It is a compile-time error if an asynchronous
   * for-in statement appears inside a synchronous function.
   */
  static const CompileTimeErrorCode ASYNC_FOR_IN_WRONG_CONTEXT =
      const CompileTimeErrorCode('ASYNC_FOR_IN_WRONG_CONTEXT',
          "The asynchronous for-in can only be used in a function marked with async or async*");

  /**
   * ??: It is a compile-time error if the function immediately enclosing a is
   * not declared asynchronous.
   */
  static const CompileTimeErrorCode AWAIT_IN_WRONG_CONTEXT =
      const CompileTimeErrorCode('AWAIT_IN_WRONG_CONTEXT',
          "The await expression can only be used in a function marked as async or async*");

  /**
   * 12.30 Identifier Reference: It is a compile-time error to use a built-in
   * identifier other than dynamic as a type annotation.
   */
  static const CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_TYPE =
      const CompileTimeErrorCode('BUILT_IN_IDENTIFIER_AS_TYPE',
          "The built-in identifier '{0}' cannot be used as a type");

  /**
   * 12.30 Identifier Reference: It is a compile-time error if a built-in
   * identifier is used as the declared name of a class, type parameter or type
   * alias.
   */
  static const CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_TYPE_NAME =
      const CompileTimeErrorCode('BUILT_IN_IDENTIFIER_AS_TYPE_NAME',
          "The built-in identifier '{0}' cannot be used as a type name");

  /**
   * 12.30 Identifier Reference: It is a compile-time error if a built-in
   * identifier is used as the declared name of a class, type parameter or type
   * alias.
   */
  static const CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME =
      const CompileTimeErrorCode('BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME',
          "The built-in identifier '{0}' cannot be used as a type alias name");

  /**
   * 12.30 Identifier Reference: It is a compile-time error if a built-in
   * identifier is used as the declared name of a class, type parameter or type
   * alias.
   */
  static const CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME =
      const CompileTimeErrorCode('BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME',
          "The built-in identifier '{0}' cannot be used as a type parameter name");

  /**
   * 13.9 Switch: It is a compile-time error if the class <i>C</i> implements
   * the operator <i>==</i>.
   */
  static const CompileTimeErrorCode CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS =
      const CompileTimeErrorCode('CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS',
          "The switch case expression type '{0}' cannot override the == operator");

  /**
   * 12.1 Constants: It is a compile-time error if evaluation of a compile-time
   * constant would raise
   * an exception.
   */
  static const CompileTimeErrorCode COMPILE_TIME_CONSTANT_RAISES_EXCEPTION =
      const CompileTimeErrorCode('COMPILE_TIME_CONSTANT_RAISES_EXCEPTION', "");

  /**
   * 7.2 Getters: It is a compile-time error if a class has both a getter and a
   * method with the same name. This restriction holds regardless of whether the
   * getter is defined explicitly or implicitly, or whether the getter or the
   * method are inherited or not.
   */
  static const CompileTimeErrorCode CONFLICTING_GETTER_AND_METHOD =
      const CompileTimeErrorCode('CONFLICTING_GETTER_AND_METHOD',
          "Class '{0}' cannot have both getter '{1}.{2}' and method with the same name");

  /**
   * 7.2 Getters: It is a compile-time error if a class has both a getter and a
   * method with the same name. This restriction holds regardless of whether the
   * getter is defined explicitly or implicitly, or whether the getter or the
   * method are inherited or not.
   */
  static const CompileTimeErrorCode CONFLICTING_METHOD_AND_GETTER =
      const CompileTimeErrorCode('CONFLICTING_METHOD_AND_GETTER',
          "Class '{0}' cannot have both method '{1}.{2}' and getter with the same name");

  /**
   * 7.6 Constructors: A constructor name always begins with the name of its
   * immediately enclosing class, and may optionally be followed by a dot and an
   * identifier <i>id</i>. It is a compile-time error if <i>id</i> is the name
   * of a member declared in the immediately enclosing class.
   */
  static const CompileTimeErrorCode CONFLICTING_CONSTRUCTOR_NAME_AND_FIELD =
      const CompileTimeErrorCode('CONFLICTING_CONSTRUCTOR_NAME_AND_FIELD',
          "'{0}' cannot be used to name a constructor and a field in this class");

  /**
   * 7.6 Constructors: A constructor name always begins with the name of its
   * immediately enclosing class, and may optionally be followed by a dot and an
   * identifier <i>id</i>. It is a compile-time error if <i>id</i> is the name
   * of a member declared in the immediately enclosing class.
   */
  static const CompileTimeErrorCode CONFLICTING_CONSTRUCTOR_NAME_AND_METHOD =
      const CompileTimeErrorCode('CONFLICTING_CONSTRUCTOR_NAME_AND_METHOD',
          "'{0}' cannot be used to name a constructor and a method in this class");

  /**
   * 7. Classes: It is a compile time error if a generic class declares a type
   * variable with the same name as the class or any of its members or
   * constructors.
   */
  static const CompileTimeErrorCode CONFLICTING_TYPE_VARIABLE_AND_CLASS =
      const CompileTimeErrorCode('CONFLICTING_TYPE_VARIABLE_AND_CLASS',
          "'{0}' cannot be used to name a type variable in a class with the same name");

  /**
   * 7. Classes: It is a compile time error if a generic class declares a type
   * variable with the same name as the class or any of its members or
   * constructors.
   */
  static const CompileTimeErrorCode CONFLICTING_TYPE_VARIABLE_AND_MEMBER =
      const CompileTimeErrorCode('CONFLICTING_TYPE_VARIABLE_AND_MEMBER',
          "'{0}' cannot be used to name a type variable and member in this class");

  /**
   * 12.11.2 Const: It is a compile-time error if evaluation of a constant
   * object results in an uncaught exception being thrown.
   */
  static const CompileTimeErrorCode CONST_CONSTRUCTOR_THROWS_EXCEPTION =
      const CompileTimeErrorCode('CONST_CONSTRUCTOR_THROWS_EXCEPTION',
          "'const' constructors cannot throw exceptions");

  /**
   * 10.6.3 Constant Constructors: It is a compile-time error if a constant
   * constructor is declared by a class C if any instance variable declared in C
   * is initialized with an expression that is not a constant expression.
   */
  static const CompileTimeErrorCode
      CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST =
      const CompileTimeErrorCode(
          'CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST',
          "Can't define the 'const' constructor because the field '{0}' is initialized with a non-constant value");

  /**
   * 7.6.3 Constant Constructors: The superinitializer that appears, explicitly
   * or implicitly, in the initializer list of a constant constructor must
   * specify a constant constructor of the superclass of the immediately
   * enclosing class or a compile-time error occurs.
   *
   * 9 Mixins: For each generative constructor named ... an implicitly declared
   * constructor named ... is declared.
   */
  static const CompileTimeErrorCode CONST_CONSTRUCTOR_WITH_MIXIN =
      const CompileTimeErrorCode('CONST_CONSTRUCTOR_WITH_MIXIN',
          "Constant constructor cannot be declared for a class with a mixin");

  /**
   * 7.6.3 Constant Constructors: The superinitializer that appears, explicitly
   * or implicitly, in the initializer list of a constant constructor must
   * specify a constant constructor of the superclass of the immediately
   * enclosing class or a compile-time error occurs.
   */
  static const CompileTimeErrorCode CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER =
      const CompileTimeErrorCode('CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER',
          "Constant constructor cannot call non-constant super constructor of '{0}'");

  /**
   * 7.6.3 Constant Constructors: It is a compile-time error if a constant
   * constructor is declared by a class that has a non-final instance variable.
   *
   * The above refers to both locally declared and inherited instance variables.
   */
  static const CompileTimeErrorCode CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD =
      const CompileTimeErrorCode('CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD',
          "Cannot define the 'const' constructor for a class with non-final fields");

  /**
   * 12.12.2 Const: It is a compile-time error if <i>T</i> is a deferred type.
   */
  static const CompileTimeErrorCode CONST_DEFERRED_CLASS =
      const CompileTimeErrorCode('CONST_DEFERRED_CLASS',
          "Deferred classes cannot be created with 'const'");

  /**
   * 6.2 Formal Parameters: It is a compile-time error if a formal parameter is
   * declared as a constant variable.
   */
  static const CompileTimeErrorCode CONST_FORMAL_PARAMETER =
      const CompileTimeErrorCode(
          'CONST_FORMAL_PARAMETER', "Parameters cannot be 'const'");

  /**
   * 5 Variables: A constant variable must be initialized to a compile-time
   * constant or a compile-time error occurs.
   */
  static const CompileTimeErrorCode CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE =
      const CompileTimeErrorCode('CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE',
          "'const' variables must be constant value");

  /**
   * 5 Variables: A constant variable must be initialized to a compile-time
   * constant or a compile-time error occurs.
   *
   * 12.1 Constants: A qualified reference to a static constant variable that is
   * not qualified by a deferred prefix.
   */
  static const CompileTimeErrorCode
      CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY =
      const CompileTimeErrorCode(
          'CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY',
          "Constant values from a deferred library cannot be used to initialized a 'const' variable");

  /**
   * 7.5 Instance Variables: It is a compile-time error if an instance variable
   * is declared to be constant.
   */
  static const CompileTimeErrorCode CONST_INSTANCE_FIELD =
      const CompileTimeErrorCode('CONST_INSTANCE_FIELD',
          "Only static fields can be declared as 'const'");

  /**
   * 12.8 Maps: It is a compile-time error if the key of an entry in a constant
   * map literal is an instance of a class that implements the operator
   * <i>==</i> unless the key is a string or integer.
   */
  static const CompileTimeErrorCode
      CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS =
      const CompileTimeErrorCode(
          'CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS',
          "The constant map entry key expression type '{0}' cannot override the == operator");

  /**
   * 5 Variables: A constant variable must be initialized to a compile-time
   * constant (12.1) or a compile-time error occurs.
   *
   * Parameters:
   * 0: the name of the uninitialized final variable
   */
  static const CompileTimeErrorCode CONST_NOT_INITIALIZED =
      const CompileTimeErrorCode('CONST_NOT_INITIALIZED',
          "The const variable '{0}' must be initialized");

  /**
   * 12.11.2 Const: An expression of one of the forms !e, e1 && e2 or e1 || e2,
   * where e, e1 and e2 are constant expressions that evaluate to a boolean
   * value.
   */
  static const CompileTimeErrorCode CONST_EVAL_TYPE_BOOL =
      const CompileTimeErrorCode('CONST_EVAL_TYPE_BOOL',
          "In constant expressions, operand(s) of this operator must be of type 'bool'");

  /**
   * 12.11.2 Const: An expression of one of the forms e1 == e2 or e1 != e2 where
   * e1 and e2 are constant expressions that evaluate to a numeric, string or
   * boolean value or to null.
   */
  static const CompileTimeErrorCode CONST_EVAL_TYPE_BOOL_NUM_STRING =
      const CompileTimeErrorCode('CONST_EVAL_TYPE_BOOL_NUM_STRING',
          "In constant expressions, operands of this operator must be of type 'bool', 'num', 'String' or 'null'");

  /**
   * 12.11.2 Const: An expression of one of the forms ~e, e1 ^ e2, e1 & e2,
   * e1 | e2, e1 >> e2 or e1 << e2, where e, e1 and e2 are constant expressions
   * that evaluate to an integer value or to null.
   */
  static const CompileTimeErrorCode CONST_EVAL_TYPE_INT =
      const CompileTimeErrorCode('CONST_EVAL_TYPE_INT',
          "In constant expressions, operand(s) of this operator must be of type 'int'");

  /**
   * 12.11.2 Const: An expression of one of the forms e, e1 + e2, e1 - e2, e1 *
   * e2, e1 / e2, e1 ~/ e2, e1 > e2, e1 < e2, e1 >= e2, e1 <= e2 or e1 % e2,
   * where e, e1 and e2 are constant expressions that evaluate to a numeric
   * value or to null.
   */
  static const CompileTimeErrorCode CONST_EVAL_TYPE_NUM =
      const CompileTimeErrorCode('CONST_EVAL_TYPE_NUM',
          "In constant expressions, operand(s) of this operator must be of type 'num'");

  /**
   * 12.11.2 Const: It is a compile-time error if evaluation of a constant
   * object results in an uncaught exception being thrown.
   */
  static const CompileTimeErrorCode CONST_EVAL_THROWS_EXCEPTION =
      const CompileTimeErrorCode('CONST_EVAL_THROWS_EXCEPTION',
          "Evaluation of this constant expression causes exception");

  /**
   * 12.11.2 Const: It is a compile-time error if evaluation of a constant
   * object results in an uncaught exception being thrown.
   */
  static const CompileTimeErrorCode CONST_EVAL_THROWS_IDBZE =
      const CompileTimeErrorCode('CONST_EVAL_THROWS_IDBZE',
          "Evaluation of this constant expression throws IntegerDivisionByZeroException");

  /**
   * 12.11.2 Const: If <i>T</i> is a parameterized type <i>S&lt;U<sub>1</sub>,
   * &hellip;, U<sub>m</sub>&gt;</i>, let <i>R = S</i>; It is a compile time
   * error if <i>S</i> is not a generic type with <i>m</i> type parameters.
   *
   * Parameters:
   * 0: the name of the type being referenced (<i>S</i>)
   * 1: the number of type parameters that were declared
   * 2: the number of type arguments provided
   *
   * See [StaticWarningCode.NEW_WITH_INVALID_TYPE_PARAMETERS], and
   * [StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS].
   */
  static const CompileTimeErrorCode CONST_WITH_INVALID_TYPE_PARAMETERS =
      const CompileTimeErrorCode('CONST_WITH_INVALID_TYPE_PARAMETERS',
          "The type '{0}' is declared with {1} type parameters, but {2} type arguments were given");

  /**
   * 12.11.2 Const: If <i>e</i> is of the form <i>const T(a<sub>1</sub>,
   * &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;,
   * x<sub>n+k</sub>: a<sub>n+k</sub>)</i> it is a compile-time error if the
   * type <i>T</i> does not declare a constant constructor with the same name as
   * the declaration of <i>T</i>.
   */
  static const CompileTimeErrorCode CONST_WITH_NON_CONST =
      const CompileTimeErrorCode('CONST_WITH_NON_CONST',
          "The constructor being called is not a 'const' constructor");

  /**
   * 12.11.2 Const: In all of the above cases, it is a compile-time error if
   * <i>a<sub>i</sub>, 1 &lt;= i &lt;= n + k</i>, is not a compile-time constant
   * expression.
   */
  static const CompileTimeErrorCode CONST_WITH_NON_CONSTANT_ARGUMENT =
      const CompileTimeErrorCode('CONST_WITH_NON_CONSTANT_ARGUMENT',
          "Arguments of a constant creation must be constant expressions");

  /**
   * 12.11.2 Const: It is a compile-time error if <i>T</i> is not a class
   * accessible in the current scope, optionally followed by type arguments.
   *
   * 12.11.2 Const: If <i>e</i> is of the form <i>const T.id(a<sub>1</sub>,
   * &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;
   * x<sub>n+k</sub>: a<sub>n+k</sub>)</i> it is a compile-time error if
   * <i>T</i> is not a class accessible in the current scope, optionally
   * followed by type arguments.
   *
   * Parameters:
   * 0: the name of the non-type element
   */
  static const CompileTimeErrorCode CONST_WITH_NON_TYPE =
      const CompileTimeErrorCode(
          'CONST_WITH_NON_TYPE', "The name '{0}' is not a class");

  /**
   * 12.11.2 Const: It is a compile-time error if <i>T</i> includes any type
   * parameters.
   */
  static const CompileTimeErrorCode CONST_WITH_TYPE_PARAMETERS =
      const CompileTimeErrorCode('CONST_WITH_TYPE_PARAMETERS',
          "The constant creation cannot use a type parameter");

  /**
   * 12.11.2 Const: It is a compile-time error if <i>T.id</i> is not the name of
   * a constant constructor declared by the type <i>T</i>.
   *
   * Parameters:
   * 0: the name of the type
   * 1: the name of the requested constant constructor
   */
  static const CompileTimeErrorCode CONST_WITH_UNDEFINED_CONSTRUCTOR =
      const CompileTimeErrorCode('CONST_WITH_UNDEFINED_CONSTRUCTOR',
          "The class '{0}' does not have a constant constructor '{1}'");

  /**
   * 12.11.2 Const: It is a compile-time error if <i>T.id</i> is not the name of
   * a constant constructor declared by the type <i>T</i>.
   *
   * Parameters:
   * 0: the name of the type
   */
  static const CompileTimeErrorCode CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT =
      const CompileTimeErrorCode('CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT',
          "The class '{0}' does not have a default constant constructor");

  /**
   * 15.3.1 Typedef: It is a compile-time error if any default values are
   * specified in the signature of a function type alias.
   */
  static const CompileTimeErrorCode DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS =
      const CompileTimeErrorCode('DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS',
          "Default values aren't allowed in typedefs");

  /**
   * 6.2.1 Required Formals: By means of a function signature that names the
   * parameter and describes its type as a function type. It is a compile-time
   * error if any default values are specified in the signature of such a
   * function type.
   */
  static const CompileTimeErrorCode DEFAULT_VALUE_IN_FUNCTION_TYPED_PARAMETER =
      const CompileTimeErrorCode('DEFAULT_VALUE_IN_FUNCTION_TYPED_PARAMETER',
          "Default values aren't allowed in function type parameters");

  /**
   * 7.6.2 Factories: It is a compile-time error if <i>k</i> explicitly
   * specifies a default value for an optional parameter.
   */
  static const CompileTimeErrorCode
      DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR =
      const CompileTimeErrorCode(
          'DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR',
          "Default values aren't allowed in factory constructors that redirect to another constructor");

  /**
   * 3.1 Scoping: It is a compile-time error if there is more than one entity
   * with the same name declared in the same scope.
   */
  static const CompileTimeErrorCode DUPLICATE_CONSTRUCTOR_DEFAULT =
      const CompileTimeErrorCode('DUPLICATE_CONSTRUCTOR_DEFAULT',
          "The default constructor is already defined");

  /**
   * 3.1 Scoping: It is a compile-time error if there is more than one entity
   * with the same name declared in the same scope.
   *
   * Parameters:
   * 0: the name of the duplicate entity
   */
  static const CompileTimeErrorCode DUPLICATE_CONSTRUCTOR_NAME =
      const CompileTimeErrorCode('DUPLICATE_CONSTRUCTOR_NAME',
          "The constructor with name '{0}' is already defined");

  /**
   * 3.1 Scoping: It is a compile-time error if there is more than one entity
   * with the same name declared in the same scope.
   *
   * 7 Classes: It is a compile-time error if a class declares two members of
   * the same name.
   *
   * 7 Classes: It is a compile-time error if a class has an instance member and
   * a static member with the same name.
   *
   * Parameters:
   * 0: the name of the duplicate entity
   */
  static const CompileTimeErrorCode DUPLICATE_DEFINITION =
      const CompileTimeErrorCode(
          'DUPLICATE_DEFINITION', "The name '{0}' is already defined");

  /**
   * 7. Classes: It is a compile-time error if a class has an instance member
   * and a static member with the same name.
   *
   * This covers the additional duplicate definition cases where inheritance has
   * to be considered.
   *
   * Parameters:
   * 0: the name of the class that has conflicting instance/static members
   * 1: the name of the conflicting members
   *
   * See [DUPLICATE_DEFINITION].
   */
  static const CompileTimeErrorCode DUPLICATE_DEFINITION_INHERITANCE =
      const CompileTimeErrorCode('DUPLICATE_DEFINITION_INHERITANCE',
          "The name '{0}' is already defined in '{1}'");

  /**
   * 12.14.2 Binding Actuals to Formals: It is a compile-time error if
   * <i>q<sub>i</sub> = q<sub>j</sub></i> for any <i>i != j</i> [where
   * <i>q<sub>i</sub></i> is the label for a named argument].
   */
  static const CompileTimeErrorCode DUPLICATE_NAMED_ARGUMENT =
      const CompileTimeErrorCode('DUPLICATE_NAMED_ARGUMENT',
          "The argument for the named parameter '{0}' was already specified");

  /**
   * SDK implementation libraries can be exported only by other SDK libraries.
   *
   * Parameters:
   * 0: the uri pointing to a library
   */
  static const CompileTimeErrorCode EXPORT_INTERNAL_LIBRARY =
      const CompileTimeErrorCode('EXPORT_INTERNAL_LIBRARY',
          "The library '{0}' is internal and cannot be exported");

  /**
   * 14.2 Exports: It is a compile-time error if the compilation unit found at
   * the specified URI is not a library declaration.
   *
   * Parameters:
   * 0: the uri pointing to a non-library declaration
   */
  static const CompileTimeErrorCode EXPORT_OF_NON_LIBRARY =
      const CompileTimeErrorCode('EXPORT_OF_NON_LIBRARY',
          "The exported library '{0}' must not have a part-of directive");

  /**
   * Enum proposal: It is a compile-time error to subclass, mix-in or implement
   * an enum.
   */
  static const CompileTimeErrorCode EXTENDS_ENUM = const CompileTimeErrorCode(
      'EXTENDS_ENUM', "Classes cannot extend an enum");

  /**
   * 7.9 Superclasses: It is a compile-time error if the extends clause of a
   * class <i>C</i> includes a type expression that does not denote a class
   * available in the lexical scope of <i>C</i>.
   *
   * Parameters:
   * 0: the name of the superclass that was not found
   */
  static const CompileTimeErrorCode EXTENDS_NON_CLASS =
      const CompileTimeErrorCode(
          'EXTENDS_NON_CLASS', "Classes can only extend other classes");

  /**
   * 12.2 Null: It is a compile-time error for a class to attempt to extend or
   * implement Null.
   *
   * 12.3 Numbers: It is a compile-time error for a class to attempt to extend
   * or implement int.
   *
   * 12.3 Numbers: It is a compile-time error for a class to attempt to extend
   * or implement double.
   *
   * 12.3 Numbers: It is a compile-time error for any type other than the types
   * int and double to
   * attempt to extend or implement num.
   *
   * 12.4 Booleans: It is a compile-time error for a class to attempt to extend
   * or implement bool.
   *
   * 12.5 Strings: It is a compile-time error for a class to attempt to extend
   * or implement String.
   *
   * Parameters:
   * 0: the name of the type that cannot be extended
   *
   * See [IMPLEMENTS_DISALLOWED_CLASS].
   */
  static const CompileTimeErrorCode EXTENDS_DISALLOWED_CLASS =
      const CompileTimeErrorCode(
          'EXTENDS_DISALLOWED_CLASS', "Classes cannot extend '{0}'");

  /**
   * 7.9 Superclasses: It is a compile-time error if the extends clause of a
   * class <i>C</i> includes a deferred type expression.
   *
   * Parameters:
   * 0: the name of the type that cannot be extended
   *
   * See [IMPLEMENTS_DEFERRED_CLASS], and [MIXIN_DEFERRED_CLASS].
   */
  static const CompileTimeErrorCode EXTENDS_DEFERRED_CLASS =
      const CompileTimeErrorCode('EXTENDS_DEFERRED_CLASS',
          "This class cannot extend the deferred class '{0}'");

  /**
   * DEP 37 extends the syntax for assert() to allow a second "message"
   * argument.  We issue this error if the user tries to supply a "message"
   * argument but the DEP is not enabled.
   */
  static const CompileTimeErrorCode EXTRA_ARGUMENT_TO_ASSERT =
      const CompileTimeErrorCode('EXTRA_ARGUMENT_TO_ASSERT',
          "Assertions only accept a single argument");

  /**
   * 12.14.2 Binding Actuals to Formals: It is a static warning if <i>m &lt;
   * h</i> or if <i>m &gt; n</i>.
   *
   * 12.11.2 Const: It is a compile-time error if evaluation of a constant
   * object results in an uncaught exception being thrown.
   *
   * Parameters:
   * 0: the maximum number of positional arguments
   * 1: the actual number of positional arguments given
   */
  static const CompileTimeErrorCode EXTRA_POSITIONAL_ARGUMENTS =
      const CompileTimeErrorCode('EXTRA_POSITIONAL_ARGUMENTS',
          "{0} positional arguments expected, but {1} found");

  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It
   * is a compile time error if more than one initializer corresponding to a
   * given instance variable appears in <i>k</i>'s list.
   */
  static const CompileTimeErrorCode FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS =
      const CompileTimeErrorCode('FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS',
          "The field '{0}' cannot be initialized twice in the same constructor");

  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It
   * is a compile time error if <i>k</i>'s initializer list contains an
   * initializer for a variable that is initialized by means of an initializing
   * formal of <i>k</i>.
   */
  static const CompileTimeErrorCode
      FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER =
      const CompileTimeErrorCode(
          'FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER',
          "Fields cannot be initialized in both the parameter list and the initializers");

  /**
   * 5 Variables: It is a compile-time error if a final instance variable that
   * has is initialized by means of an initializing formal of a constructor is
   * also initialized elsewhere in the same constructor.
   *
   * Parameters:
   * 0: the name of the field in question
   */
  static const CompileTimeErrorCode FINAL_INITIALIZED_MULTIPLE_TIMES =
      const CompileTimeErrorCode('FINAL_INITIALIZED_MULTIPLE_TIMES',
          "'{0}' is a final field and so can only be set once");

  /**
   * 7.6.1 Generative Constructors: It is a compile-time error if an
   * initializing formal is used by a function other than a non-redirecting
   * generative constructor.
   */
  static const CompileTimeErrorCode FIELD_INITIALIZER_FACTORY_CONSTRUCTOR =
      const CompileTimeErrorCode('FIELD_INITIALIZER_FACTORY_CONSTRUCTOR',
          "Initializing formal fields cannot be used in factory constructors");

  /**
   * 7.6.1 Generative Constructors: It is a compile-time error if an
   * initializing formal is used by a function other than a non-redirecting
   * generative constructor.
   */
  static const CompileTimeErrorCode FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR =
      const CompileTimeErrorCode('FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR',
          "Initializing formal fields can only be used in constructors");

  /**
   * 7.6.1 Generative Constructors: A generative constructor may be redirecting,
   * in which case its only action is to invoke another generative constructor.
   *
   * 7.6.1 Generative Constructors: It is a compile-time error if an
   * initializing formal is used by a function other than a non-redirecting
   * generative constructor.
   */
  static const CompileTimeErrorCode FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR =
      const CompileTimeErrorCode('FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR',
          "The redirecting constructor cannot have a field initializer");

  /**
   * 7.2 Getters: It is a compile-time error if a class has both a getter and a
   * method with the same name.
   *
   * Parameters:
   * 0: the conflicting name of the getter and method
   */
  static const CompileTimeErrorCode GETTER_AND_METHOD_WITH_SAME_NAME =
      const CompileTimeErrorCode('GETTER_AND_METHOD_WITH_SAME_NAME',
          "'{0}' cannot be used to name a getter, there is already a method with the same name");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the implements clause
   * of a class <i>C</i> specifies a malformed type or deferred type as a
   * superinterface.
   *
   * Parameters:
   * 0: the name of the type that cannot be extended
   *
   * See [EXTENDS_DEFERRED_CLASS], and [MIXIN_DEFERRED_CLASS].
   */
  static const CompileTimeErrorCode IMPLEMENTS_DEFERRED_CLASS =
      const CompileTimeErrorCode('IMPLEMENTS_DEFERRED_CLASS',
          "This class cannot implement the deferred class '{0}'");

  /**
   * 12.2 Null: It is a compile-time error for a class to attempt to extend or
   * implement Null.
   *
   * 12.3 Numbers: It is a compile-time error for a class to attempt to extend
   * or implement int.
   *
   * 12.3 Numbers: It is a compile-time error for a class to attempt to extend
   * or implement double.
   *
   * 12.3 Numbers: It is a compile-time error for any type other than the types
   * int and double to
   * attempt to extend or implement num.
   *
   * 12.4 Booleans: It is a compile-time error for a class to attempt to extend
   * or implement bool.
   *
   * 12.5 Strings: It is a compile-time error for a class to attempt to extend
   * or implement String.
   *
   * Parameters:
   * 0: the name of the type that cannot be implemented
   *
   * See [EXTENDS_DISALLOWED_CLASS].
   */
  static const CompileTimeErrorCode IMPLEMENTS_DISALLOWED_CLASS =
      const CompileTimeErrorCode(
          'IMPLEMENTS_DISALLOWED_CLASS', "Classes cannot implement '{0}'");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the implements clause
   * of a class includes type dynamic.
   */
  static const CompileTimeErrorCode IMPLEMENTS_DYNAMIC =
      const CompileTimeErrorCode(
          'IMPLEMENTS_DYNAMIC', "Classes cannot implement 'dynamic'");

  /**
   * Enum proposal: It is a compile-time error to subclass, mix-in or implement
   * an enum.
   */
  static const CompileTimeErrorCode IMPLEMENTS_ENUM =
      const CompileTimeErrorCode(
          'IMPLEMENTS_ENUM', "Classes cannot implement an enum");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the implements clause
   * of a class <i>C</i> includes a type expression that does not denote a class
   * available in the lexical scope of <i>C</i>.
   *
   * Parameters:
   * 0: the name of the interface that was not found
   */
  static const CompileTimeErrorCode IMPLEMENTS_NON_CLASS =
      const CompileTimeErrorCode(
          'IMPLEMENTS_NON_CLASS', "Classes can only implement other classes");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if a type <i>T</i> appears
   * more than once in the implements clause of a class.
   *
   * Parameters:
   * 0: the name of the class that is implemented more than once
   */
  static const CompileTimeErrorCode IMPLEMENTS_REPEATED =
      const CompileTimeErrorCode(
          'IMPLEMENTS_REPEATED', "'{0}' can only be implemented once");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the superclass of a
   * class <i>C</i> appears in the implements clause of <i>C</i>.
   *
   * Parameters:
   * 0: the name of the class that appears in both "extends" and "implements"
   *    clauses
   */
  static const CompileTimeErrorCode IMPLEMENTS_SUPER_CLASS =
      const CompileTimeErrorCode('IMPLEMENTS_SUPER_CLASS',
          "'{0}' cannot be used in both 'extends' and 'implements' clauses");

  /**
   * 7.6.1 Generative Constructors: Note that <b>this</b> is not in scope on the
   * right hand side of an initializer.
   *
   * 12.10 This: It is a compile-time error if this appears in a top-level
   * function or variable initializer, in a factory constructor, or in a static
   * method or variable initializer, or in the initializer of an instance
   * variable.
   *
   * Parameters:
   * 0: the name of the type in question
   */
  static const CompileTimeErrorCode IMPLICIT_THIS_REFERENCE_IN_INITIALIZER =
      const CompileTimeErrorCode('IMPLICIT_THIS_REFERENCE_IN_INITIALIZER',
          "Only static members can be accessed in initializers");

  /**
   * SDK implementation libraries can be imported only by other SDK libraries.
   *
   * Parameters:
   * 0: the uri pointing to a library
   */
  static const CompileTimeErrorCode IMPORT_INTERNAL_LIBRARY =
      const CompileTimeErrorCode('IMPORT_INTERNAL_LIBRARY',
          "The library '{0}' is internal and cannot be imported");

  /**
   * 14.1 Imports: It is a compile-time error if the specified URI of an
   * immediate import does not refer to a library declaration.
   *
   * Parameters:
   * 0: the uri pointing to a non-library declaration
   *
   * See [StaticWarningCode.IMPORT_OF_NON_LIBRARY].
   */
  static const CompileTimeErrorCode IMPORT_OF_NON_LIBRARY =
      const CompileTimeErrorCode('IMPORT_OF_NON_LIBRARY',
          "The imported library '{0}' must not have a part-of directive");

  /**
   * 13.9 Switch: It is a compile-time error if values of the expressions
   * <i>e<sub>k</sub></i> are not instances of the same class <i>C</i>, for all
   * <i>1 &lt;= k &lt;= n</i>.
   *
   * Parameters:
   * 0: the expression source code that is the unexpected type
   * 1: the name of the expected type
   */
  static const CompileTimeErrorCode INCONSISTENT_CASE_EXPRESSION_TYPES =
      const CompileTimeErrorCode('INCONSISTENT_CASE_EXPRESSION_TYPES',
          "Case expressions must have the same types, '{0}' is not a '{1}'");

  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It
   * is a compile-time error if <i>k</i>'s initializer list contains an
   * initializer for a variable that is not an instance variable declared in the
   * immediately surrounding class.
   *
   * Parameters:
   * 0: the name of the initializing formal that is not an instance variable in
   *    the immediately enclosing class
   *
   * See [INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD].
   */
  static const CompileTimeErrorCode INITIALIZER_FOR_NON_EXISTENT_FIELD =
      const CompileTimeErrorCode('INITIALIZER_FOR_NON_EXISTENT_FIELD',
          "'{0}' is not a variable in the enclosing class");

  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It
   * is a compile-time error if <i>k</i>'s initializer list contains an
   * initializer for a variable that is not an instance variable declared in the
   * immediately surrounding class.
   *
   * Parameters:
   * 0: the name of the initializing formal that is a static variable in the
   *    immediately enclosing class
   *
   * See [INITIALIZING_FORMAL_FOR_STATIC_FIELD].
   */
  static const CompileTimeErrorCode INITIALIZER_FOR_STATIC_FIELD =
      const CompileTimeErrorCode('INITIALIZER_FOR_STATIC_FIELD',
          "'{0}' is a static variable in the enclosing class, variables initialized in a constructor cannot be static");

  /**
   * 7.6.1 Generative Constructors: An initializing formal has the form
   * <i>this.id</i>. It is a compile-time error if <i>id</i> is not the name of
   * an instance variable of the immediately enclosing class.
   *
   * Parameters:
   * 0: the name of the initializing formal that is not an instance variable in
   *    the immediately enclosing class
   *
   * See [INITIALIZING_FORMAL_FOR_STATIC_FIELD], and
   * [INITIALIZER_FOR_NON_EXISTENT_FIELD].
   */
  static const CompileTimeErrorCode INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD =
      const CompileTimeErrorCode('INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD',
          "'{0}' is not a variable in the enclosing class");

  /**
   * 7.6.1 Generative Constructors: An initializing formal has the form
   * <i>this.id</i>. It is a compile-time error if <i>id</i> is not the name of
   * an instance variable of the immediately enclosing class.
   *
   * Parameters:
   * 0: the name of the initializing formal that is a static variable in the
   *    immediately enclosing class
   *
   * See [INITIALIZER_FOR_STATIC_FIELD].
   */
  static const CompileTimeErrorCode INITIALIZING_FORMAL_FOR_STATIC_FIELD =
      const CompileTimeErrorCode('INITIALIZING_FORMAL_FOR_STATIC_FIELD',
          "'{0}' is a static field in the enclosing class, fields initialized in a constructor cannot be static");

  /**
   * 12.30 Identifier Reference: Otherwise, e is equivalent to the property
   * extraction <b>this</b>.<i>id</i>.
   */
  static const CompileTimeErrorCode INSTANCE_MEMBER_ACCESS_FROM_FACTORY =
      const CompileTimeErrorCode('INSTANCE_MEMBER_ACCESS_FROM_FACTORY',
          "Instance members cannot be accessed from a factory constructor");

  /**
   * 12.30 Identifier Reference: Otherwise, e is equivalent to the property
   * extraction <b>this</b>.<i>id</i>.
   */
  static const CompileTimeErrorCode INSTANCE_MEMBER_ACCESS_FROM_STATIC =
      const CompileTimeErrorCode('INSTANCE_MEMBER_ACCESS_FROM_STATIC',
          "Instance members cannot be accessed from a static method");

  /**
   * Enum proposal: It is also a compile-time error to explicitly instantiate an
   * enum via 'new' or 'const' or to access its private fields.
   */
  static const CompileTimeErrorCode INSTANTIATE_ENUM =
      const CompileTimeErrorCode(
          'INSTANTIATE_ENUM', "Enums cannot be instantiated");

  /**
   * 11 Metadata: Metadata consists of a series of annotations, each of which
   * begin with the character @, followed by a constant expression that must be
   * either a reference to a compile-time constant variable, or a call to a
   * constant constructor.
   */
  static const CompileTimeErrorCode INVALID_ANNOTATION = const CompileTimeErrorCode(
      'INVALID_ANNOTATION',
      "Annotation can be only constant variable or constant constructor invocation");

  /**
   * 11 Metadata: Metadata consists of a series of annotations, each of which
   * begin with the character @, followed by a constant expression that must be
   * either a reference to a compile-time constant variable, or a call to a
   * constant constructor.
   *
   * 12.1 Constants: A qualified reference to a static constant variable that is
   * not qualified by a deferred prefix.
   */
  static const CompileTimeErrorCode INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY =
      const CompileTimeErrorCode('INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY',
          "Constant values from a deferred library cannot be used as annotations");

  /**
   * 15.31 Identifier Reference: It is a compile-time error if any of the
   * identifiers async, await or yield is used as an identifier in a function
   * body marked with either async, async* or sync*.
   */
  static const CompileTimeErrorCode INVALID_IDENTIFIER_IN_ASYNC =
      const CompileTimeErrorCode('INVALID_IDENTIFIER_IN_ASYNC',
          "The identifier '{0}' cannot be used in a function marked with async, async* or sync*");

  /**
   * 9. Functions: It is a compile-time error if an async, async* or sync*
   * modifier is attached to the body of a setter or constructor.
   */
  static const CompileTimeErrorCode INVALID_MODIFIER_ON_CONSTRUCTOR =
      const CompileTimeErrorCode('INVALID_MODIFIER_ON_CONSTRUCTOR',
          "The modifier '{0}' cannot be applied to the body of a constructor");

  /**
   * 9. Functions: It is a compile-time error if an async, async* or sync*
   * modifier is attached to the body of a setter or constructor.
   */
  static const CompileTimeErrorCode INVALID_MODIFIER_ON_SETTER =
      const CompileTimeErrorCode('INVALID_MODIFIER_ON_SETTER',
          "The modifier '{0}' cannot be applied to the body of a setter");

  /**
   * TODO(brianwilkerson) Remove this when we have decided on how to report
   * errors in compile-time constants. Until then, this acts as a placeholder
   * for more informative errors.
   *
   * See TODOs in ConstantVisitor
   */
  static const CompileTimeErrorCode INVALID_CONSTANT =
      const CompileTimeErrorCode('INVALID_CONSTANT', "Invalid constant value");

  /**
   * 7.6 Constructors: It is a compile-time error if the name of a constructor
   * is not a constructor name.
   */
  static const CompileTimeErrorCode INVALID_CONSTRUCTOR_NAME =
      const CompileTimeErrorCode(
          'INVALID_CONSTRUCTOR_NAME', "Invalid constructor name");

  /**
   * 7.6.2 Factories: It is a compile-time error if <i>M</i> is not the name of
   * the immediately enclosing class.
   */
  static const CompileTimeErrorCode INVALID_FACTORY_NAME_NOT_A_CLASS =
      const CompileTimeErrorCode('INVALID_FACTORY_NAME_NOT_A_CLASS',
          "The name of the immediately enclosing class expected");

  /**
   * 12.10 This: It is a compile-time error if this appears in a top-level
   * function or variable initializer, in a factory constructor, or in a static
   * method or variable initializer, or in the initializer of an instance
   * variable.
   */
  static const CompileTimeErrorCode INVALID_REFERENCE_TO_THIS =
      const CompileTimeErrorCode('INVALID_REFERENCE_TO_THIS',
          "Invalid reference to 'this' expression");

  /**
   * 12.6 Lists: It is a compile time error if the type argument of a constant
   * list literal includes a type parameter.
   *
   * Parameters:
   * 0: the name of the type parameter
   */
  static const CompileTimeErrorCode INVALID_TYPE_ARGUMENT_IN_CONST_LIST =
      const CompileTimeErrorCode('INVALID_TYPE_ARGUMENT_IN_CONST_LIST',
          "Constant list literals cannot include a type parameter as a type argument, such as '{0}'");

  /**
   * 12.7 Maps: It is a compile time error if the type arguments of a constant
   * map literal include a type parameter.
   *
   * Parameters:
   * 0: the name of the type parameter
   */
  static const CompileTimeErrorCode INVALID_TYPE_ARGUMENT_IN_CONST_MAP =
      const CompileTimeErrorCode('INVALID_TYPE_ARGUMENT_IN_CONST_MAP',
          "Constant map literals cannot include a type parameter as a type argument, such as '{0}'");

  /**
   * 14.2 Exports: It is a compile-time error if the compilation unit found at
   * the specified URI is not a library declaration.
   *
   * 14.1 Imports: It is a compile-time error if the compilation unit found at
   * the specified URI is not a library declaration.
   *
   * 14.3 Parts: It is a compile time error if the contents of the URI are not a
   * valid part declaration.
   *
   * Parameters:
   * 0: the URI that is invalid
   *
   * See [URI_DOES_NOT_EXIST].
   */
  static const CompileTimeErrorCode INVALID_URI =
      const CompileTimeErrorCode('INVALID_URI', "Invalid URI syntax: '{0}'");

  /**
   * 13.13 Break: It is a compile-time error if no such statement
   * <i>s<sub>E</sub></i> exists within the innermost function in which
   * <i>s<sub>b</sub></i> occurs.
   *
   * 13.14 Continue: It is a compile-time error if no such statement or case
   * clause <i>s<sub>E</sub></i> exists within the innermost function in which
   * <i>s<sub>c</sub></i> occurs.
   *
   * Parameters:
   * 0: the name of the unresolvable label
   */
  static const CompileTimeErrorCode LABEL_IN_OUTER_SCOPE =
      const CompileTimeErrorCode('LABEL_IN_OUTER_SCOPE',
          "Cannot reference label '{0}' declared in an outer method");

  /**
   * 13.13 Break: It is a compile-time error if no such statement
   * <i>s<sub>E</sub></i> exists within the innermost function in which
   * <i>s<sub>b</sub></i> occurs.
   *
   * 13.14 Continue: It is a compile-time error if no such statement or case
   * clause <i>s<sub>E</sub></i> exists within the innermost function in which
   * <i>s<sub>c</sub></i> occurs.
   *
   * Parameters:
   * 0: the name of the unresolvable label
   */
  static const CompileTimeErrorCode LABEL_UNDEFINED =
      const CompileTimeErrorCode(
          'LABEL_UNDEFINED', "Cannot reference undefined label '{0}'");

  /**
   * 7 Classes: It is a compile time error if a class <i>C</i> declares a member
   * with the same name as <i>C</i>.
   */
  static const CompileTimeErrorCode MEMBER_WITH_CLASS_NAME =
      const CompileTimeErrorCode('MEMBER_WITH_CLASS_NAME',
          "Class members cannot have the same name as the enclosing class");

  /**
   * 7.2 Getters: It is a compile-time error if a class has both a getter and a
   * method with the same name.
   *
   * Parameters:
   * 0: the conflicting name of the getter and method
   */
  static const CompileTimeErrorCode METHOD_AND_GETTER_WITH_SAME_NAME =
      const CompileTimeErrorCode('METHOD_AND_GETTER_WITH_SAME_NAME',
          "'{0}' cannot be used to name a method, there is already a getter with the same name");

  /**
   * 12.1 Constants: A constant expression is ... a constant list literal.
   */
  static const CompileTimeErrorCode MISSING_CONST_IN_LIST_LITERAL =
      const CompileTimeErrorCode('MISSING_CONST_IN_LIST_LITERAL',
          "List literals must be prefixed with 'const' when used as a constant expression");

  /**
   * 12.1 Constants: A constant expression is ... a constant map literal.
   */
  static const CompileTimeErrorCode MISSING_CONST_IN_MAP_LITERAL =
      const CompileTimeErrorCode('MISSING_CONST_IN_MAP_LITERAL',
          "Map literals must be prefixed with 'const' when used as a constant expression");

  /**
   * 9 Mixins: It is a compile-time error if a declared or derived mixin
   * explicitly declares a constructor.
   *
   * Parameters:
   * 0: the name of the mixin that is invalid
   */
  static const CompileTimeErrorCode MIXIN_DECLARES_CONSTRUCTOR =
      const CompileTimeErrorCode('MIXIN_DECLARES_CONSTRUCTOR',
          "The class '{0}' cannot be used as a mixin because it declares a constructor");

  /**
   * 9.1 Mixin Application: It is a compile-time error if the with clause of a
   * mixin application <i>C</i> includes a deferred type expression.
   *
   * Parameters:
   * 0: the name of the type that cannot be extended
   *
   * See [EXTENDS_DEFERRED_CLASS], and [IMPLEMENTS_DEFERRED_CLASS].
   */
  static const CompileTimeErrorCode MIXIN_DEFERRED_CLASS =
      const CompileTimeErrorCode('MIXIN_DEFERRED_CLASS',
          "This class cannot mixin the deferred class '{0}'");

  /**
   * Not yet in the spec, but consistent with VM behavior.  It is a
   * compile-time error if all of the constructors of a mixin's base class have
   * at least one optional parameter (since only constructors that lack
   * optional parameters can be forwarded to the mixin).  See
   * https://code.google.com/p/dart/issues/detail?id=15101#c4
   */
  static const CompileTimeErrorCode MIXIN_HAS_NO_CONSTRUCTORS =
      const CompileTimeErrorCode(
          'MIXIN_HAS_NO_CONSTRUCTORS',
          "This mixin application is invalid because all of the constructors "
          "in the base class '{0}' have optional parameters.");

  /**
   * 9 Mixins: It is a compile-time error if a mixin is derived from a class
   * whose superclass is not Object.
   *
   * Parameters:
   * 0: the name of the mixin that is invalid
   */
  static const CompileTimeErrorCode MIXIN_INHERITS_FROM_NOT_OBJECT =
      const CompileTimeErrorCode('MIXIN_INHERITS_FROM_NOT_OBJECT',
          "The class '{0}' cannot be used as a mixin because it extends a class other than Object");

  /**
   * 12.2 Null: It is a compile-time error for a class to attempt to extend or
   * implement Null.
   *
   * 12.3 Numbers: It is a compile-time error for a class to attempt to extend
   * or implement int.
   *
   * 12.3 Numbers: It is a compile-time error for a class to attempt to extend
   * or implement double.
   *
   * 12.3 Numbers: It is a compile-time error for any type other than the types
   * int and double to attempt to extend or implement num.
   *
   * 12.4 Booleans: It is a compile-time error for a class to attempt to extend
   * or implement bool.
   *
   * 12.5 Strings: It is a compile-time error for a class to attempt to extend
   * or implement String.
   *
   * Parameters:
   * 0: the name of the type that cannot be extended
   *
   * See [IMPLEMENTS_DISALLOWED_CLASS].
   */
  static const CompileTimeErrorCode MIXIN_OF_DISALLOWED_CLASS =
      const CompileTimeErrorCode(
          'MIXIN_OF_DISALLOWED_CLASS', "Classes cannot mixin '{0}'");

  /**
   * Enum proposal: It is a compile-time error to subclass, mix-in or implement
   * an enum.
   */
  static const CompileTimeErrorCode MIXIN_OF_ENUM = const CompileTimeErrorCode(
      'MIXIN_OF_ENUM', "Classes cannot mixin an enum");

  /**
   * 9.1 Mixin Application: It is a compile-time error if <i>M</i> does not
   * denote a class or mixin available in the immediately enclosing scope.
   */
  static const CompileTimeErrorCode MIXIN_OF_NON_CLASS =
      const CompileTimeErrorCode(
          'MIXIN_OF_NON_CLASS', "Classes can only mixin other classes");

  /**
   * 9 Mixins: It is a compile-time error if a declared or derived mixin refers
   * to super.
   */
  static const CompileTimeErrorCode MIXIN_REFERENCES_SUPER =
      const CompileTimeErrorCode('MIXIN_REFERENCES_SUPER',
          "The class '{0}' cannot be used as a mixin because it references 'super'");

  /**
   * 9.1 Mixin Application: It is a compile-time error if <i>S</i> does not
   * denote a class available in the immediately enclosing scope.
   */
  static const CompileTimeErrorCode MIXIN_WITH_NON_CLASS_SUPERCLASS =
      const CompileTimeErrorCode('MIXIN_WITH_NON_CLASS_SUPERCLASS',
          "Mixin can only be applied to class");

  /**
   * 7.6.1 Generative Constructors: A generative constructor may be redirecting,
   * in which case its only action is to invoke another generative constructor.
   */
  static const CompileTimeErrorCode
      MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS = const CompileTimeErrorCode(
          'MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS',
          "Constructor may have at most one 'this' redirection");

  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor.
   * Then <i>k</i> may include at most one superinitializer in its initializer
   * list or a compile time error occurs.
   */
  static const CompileTimeErrorCode MULTIPLE_SUPER_INITIALIZERS =
      const CompileTimeErrorCode('MULTIPLE_SUPER_INITIALIZERS',
          "Constructor may have at most one 'super' initializer");

  /**
   * 11 Metadata: Metadata consists of a series of annotations, each of which
   * begin with the character @, followed by a constant expression that must be
   * either a reference to a compile-time constant variable, or a call to a
   * constant constructor.
   */
  static const CompileTimeErrorCode NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS =
      const CompileTimeErrorCode('NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS',
          "Annotation creation must have arguments");

  /**
   * 7.6.1 Generative Constructors: If no superinitializer is provided, an
   * implicit superinitializer of the form <b>super</b>() is added at the end of
   * <i>k</i>'s initializer list, unless the enclosing class is class
   * <i>Object</i>.
   *
   * 7.6.1 Generative constructors. It is a compile-time error if class <i>S</i>
   * does not declare a generative constructor named <i>S</i> (respectively
   * <i>S.id</i>)
   */
  static const CompileTimeErrorCode NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT =
      const CompileTimeErrorCode('NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT',
          "The class '{0}' does not have a default constructor");

  /**
   * 7.6 Constructors: Iff no constructor is specified for a class <i>C</i>, it
   * implicitly has a default constructor C() : <b>super<b>() {}, unless
   * <i>C</i> is class <i>Object</i>.
   *
   * 7.6.1 Generative constructors. It is a compile-time error if class <i>S</i>
   * does not declare a generative constructor named <i>S</i> (respectively
   * <i>S.id</i>)
   */
  static const CompileTimeErrorCode NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT =
      const CompileTimeErrorCode('NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT',
          "The class '{0}' does not have a default constructor");

  /**
   * 13.2 Expression Statements: It is a compile-time error if a non-constant
   * map literal that has no explicit type arguments appears in a place where a
   * statement is expected.
   */
  static const CompileTimeErrorCode NON_CONST_MAP_AS_EXPRESSION_STATEMENT =
      const CompileTimeErrorCode('NON_CONST_MAP_AS_EXPRESSION_STATEMENT',
          "A non-constant map literal without type arguments cannot be used as an expression statement");

  /**
   * 13.9 Switch: Given a switch statement of the form <i>switch (e) {
   * label<sub>11</sub> &hellip; label<sub>1j1</sub> case e<sub>1</sub>:
   * s<sub>1</sub> &hellip; label<sub>n1</sub> &hellip; label<sub>njn</sub> case
   * e<sub>n</sub>: s<sub>n</sub> default: s<sub>n+1</sub>}</i> or the form
   * <i>switch (e) { label<sub>11</sub> &hellip; label<sub>1j1</sub> case
   * e<sub>1</sub>: s<sub>1</sub> &hellip; label<sub>n1</sub> &hellip;
   * label<sub>njn</sub> case e<sub>n</sub>: s<sub>n</sub>}</i>, it is a
   * compile-time error if the expressions <i>e<sub>k</sub></i> are not
   * compile-time constants, for all <i>1 &lt;= k &lt;= n</i>.
   */
  static const CompileTimeErrorCode NON_CONSTANT_CASE_EXPRESSION =
      const CompileTimeErrorCode(
          'NON_CONSTANT_CASE_EXPRESSION', "Case expressions must be constant");

  /**
   * 13.9 Switch: Given a switch statement of the form <i>switch (e) {
   * label<sub>11</sub> &hellip; label<sub>1j1</sub> case e<sub>1</sub>:
   * s<sub>1</sub> &hellip; label<sub>n1</sub> &hellip; label<sub>njn</sub> case
   * e<sub>n</sub>: s<sub>n</sub> default: s<sub>n+1</sub>}</i> or the form
   * <i>switch (e) { label<sub>11</sub> &hellip; label<sub>1j1</sub> case
   * e<sub>1</sub>: s<sub>1</sub> &hellip; label<sub>n1</sub> &hellip;
   * label<sub>njn</sub> case e<sub>n</sub>: s<sub>n</sub>}</i>, it is a
   * compile-time error if the expressions <i>e<sub>k</sub></i> are not
   * compile-time constants, for all <i>1 &lt;= k &lt;= n</i>.
   *
   * 12.1 Constants: A qualified reference to a static constant variable that is
   * not qualified by a deferred prefix.
   */
  static const CompileTimeErrorCode
      NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY =
      const CompileTimeErrorCode(
          'NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY',
          "Constant values from a deferred library cannot be used as a case expression");

  /**
   * 6.2.2 Optional Formals: It is a compile-time error if the default value of
   * an optional parameter is not a compile-time constant.
   */
  static const CompileTimeErrorCode NON_CONSTANT_DEFAULT_VALUE =
      const CompileTimeErrorCode('NON_CONSTANT_DEFAULT_VALUE',
          "Default values of an optional parameter must be constant");

  /**
   * 6.2.2 Optional Formals: It is a compile-time error if the default value of
   * an optional parameter is not a compile-time constant.
   *
   * 12.1 Constants: A qualified reference to a static constant variable that is
   * not qualified by a deferred prefix.
   */
  static const CompileTimeErrorCode
      NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY =
      const CompileTimeErrorCode(
          'NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY',
          "Constant values from a deferred library cannot be used as a default parameter value");

  /**
   * 12.6 Lists: It is a compile time error if an element of a constant list
   * literal is not a compile-time constant.
   */
  static const CompileTimeErrorCode NON_CONSTANT_LIST_ELEMENT =
      const CompileTimeErrorCode('NON_CONSTANT_LIST_ELEMENT',
          "'const' lists must have all constant values");

  /**
   * 12.6 Lists: It is a compile time error if an element of a constant list
   * literal is not a compile-time constant.
   *
   * 12.1 Constants: A qualified reference to a static constant variable that is
   * not qualified by a deferred prefix.
   */
  static const CompileTimeErrorCode
      NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY =
      const CompileTimeErrorCode(
          'NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY',
          "Constant values from a deferred library cannot be used as values in a 'const' list");

  /**
   * 12.7 Maps: It is a compile time error if either a key or a value of an
   * entry in a constant map literal is not a compile-time constant.
   */
  static const CompileTimeErrorCode NON_CONSTANT_MAP_KEY =
      const CompileTimeErrorCode(
          'NON_CONSTANT_MAP_KEY', "The keys in a map must be constant");

  /**
   * 12.7 Maps: It is a compile time error if either a key or a value of an
   * entry in a constant map literal is not a compile-time constant.
   *
   * 12.1 Constants: A qualified reference to a static constant variable that is
   * not qualified by a deferred prefix.
   */
  static const CompileTimeErrorCode NON_CONSTANT_MAP_KEY_FROM_DEFERRED_LIBRARY =
      const CompileTimeErrorCode('NON_CONSTANT_MAP_KEY_FROM_DEFERRED_LIBRARY',
          "Constant values from a deferred library cannot be used as keys in a map");

  /**
   * 12.7 Maps: It is a compile time error if either a key or a value of an
   * entry in a constant map literal is not a compile-time constant.
   */
  static const CompileTimeErrorCode NON_CONSTANT_MAP_VALUE =
      const CompileTimeErrorCode('NON_CONSTANT_MAP_VALUE',
          "The values in a 'const' map must be constant");

  /**
   * 12.7 Maps: It is a compile time error if either a key or a value of an
   * entry in a constant map literal is not a compile-time constant.
   *
   * 12.1 Constants: A qualified reference to a static constant variable that is
   * not qualified by a deferred prefix.
   */
  static const CompileTimeErrorCode
      NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY = const CompileTimeErrorCode(
          'NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY',
          "Constant values from a deferred library cannot be used as values in a 'const' map");

  /**
   * 11 Metadata: Metadata consists of a series of annotations, each of which
   * begin with the character @, followed by a constant expression that must be
   * either a reference to a compile-time constant variable, or a call to a
   * constant constructor.
   *
   * "From deferred library" case is covered by
   * [CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY].
   */
  static const CompileTimeErrorCode NON_CONSTANT_ANNOTATION_CONSTRUCTOR =
      const CompileTimeErrorCode('NON_CONSTANT_ANNOTATION_CONSTRUCTOR',
          "Annotation creation can use only 'const' constructor");

  /**
   * 7.6.3 Constant Constructors: Any expression that appears within the
   * initializer list of a constant constructor must be a potentially constant
   * expression, or a compile-time error occurs.
   */
  static const CompileTimeErrorCode NON_CONSTANT_VALUE_IN_INITIALIZER =
      const CompileTimeErrorCode('NON_CONSTANT_VALUE_IN_INITIALIZER',
          "Initializer expressions in constant constructors must be constants");

  /**
   * 7.6.3 Constant Constructors: Any expression that appears within the
   * initializer list of a constant constructor must be a potentially constant
   * expression, or a compile-time error occurs.
   *
   * 12.1 Constants: A qualified reference to a static constant variable that is
   * not qualified by a deferred prefix.
   */
  static const CompileTimeErrorCode
      NON_CONSTANT_VALUE_IN_INITIALIZER_FROM_DEFERRED_LIBRARY =
      const CompileTimeErrorCode(
          'NON_CONSTANT_VALUE_IN_INITIALIZER_FROM_DEFERRED_LIBRARY',
          "Constant values from a deferred library cannot be used as constant initializers");

  /**
   * 12.14.2 Binding Actuals to Formals: It is a static warning if <i>m < h</i>
   * or if <i>m > n</i>.
   *
   * 12.11.2 Const: It is a compile-time error if evaluation of a constant
   * object results in an uncaught exception being thrown.
   *
   * Parameters:
   * 0: the expected number of required arguments
   * 1: the actual number of positional arguments given
   */
  static const CompileTimeErrorCode NOT_ENOUGH_REQUIRED_ARGUMENTS =
      const CompileTimeErrorCode('NOT_ENOUGH_REQUIRED_ARGUMENTS',
          "{0} required argument(s) expected, but {1} found");

  /**
   * 7.6.1 Generative Constructors: Let <i>C</i> be the class in which the
   * superinitializer appears and let <i>S</i> be the superclass of <i>C</i>.
   * Let <i>k</i> be a generative constructor. It is a compile-time error if
   * class <i>S</i> does not declare a generative constructor named <i>S</i>
   * (respectively <i>S.id</i>)
   */
  static const CompileTimeErrorCode NON_GENERATIVE_CONSTRUCTOR =
      const CompileTimeErrorCode('NON_GENERATIVE_CONSTRUCTOR',
          "The generative constructor '{0}' expected, but factory found");

  /**
   * 7.9 Superclasses: It is a compile-time error to specify an extends clause
   * for class Object.
   */
  static const CompileTimeErrorCode OBJECT_CANNOT_EXTEND_ANOTHER_CLASS =
      const CompileTimeErrorCode('OBJECT_CANNOT_EXTEND_ANOTHER_CLASS', "");

  /**
   * 7.1.1 Operators: It is a compile-time error to declare an optional
   * parameter in an operator.
   */
  static const CompileTimeErrorCode OPTIONAL_PARAMETER_IN_OPERATOR =
      const CompileTimeErrorCode('OPTIONAL_PARAMETER_IN_OPERATOR',
          "Optional parameters are not allowed when defining an operator");

  /**
   * 14.3 Parts: It is a compile time error if the contents of the URI are not a
   * valid part declaration.
   *
   * Parameters:
   * 0: the uri pointing to a non-library declaration
   */
  static const CompileTimeErrorCode PART_OF_NON_PART =
      const CompileTimeErrorCode('PART_OF_NON_PART',
          "The included part '{0}' must have a part-of directive");

  /**
   * 14.1 Imports: It is a compile-time error if the current library declares a
   * top-level member named <i>p</i>.
   */
  static const CompileTimeErrorCode PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER =
      const CompileTimeErrorCode('PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER',
          "The name '{0}' is already used as an import prefix and cannot be used to name a top-level element");

  /**
   * 16.32 Identifier Reference: If d is a prefix p, a compile-time error
   * occurs unless the token immediately following d is '.'.
   */
  static const CompileTimeErrorCode PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT =
      const CompileTimeErrorCode('PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT',
          "The name '{0}' refers to an import prefix, so it must be followed by '.'");

  /**
   * 6.2.2 Optional Formals: It is a compile-time error if the name of a named
   * optional parameter begins with an '_' character.
   */
  static const CompileTimeErrorCode PRIVATE_OPTIONAL_PARAMETER =
      const CompileTimeErrorCode('PRIVATE_OPTIONAL_PARAMETER',
          "Named optional parameters cannot start with an underscore");

  /**
   * 12.1 Constants: It is a compile-time error if the value of a compile-time
   * constant expression depends on itself.
   */
  static const CompileTimeErrorCode RECURSIVE_COMPILE_TIME_CONSTANT =
      const CompileTimeErrorCode('RECURSIVE_COMPILE_TIME_CONSTANT',
          "Compile-time constant expression depends on itself");

  /**
   * 7.6.1 Generative Constructors: A generative constructor may be redirecting,
   * in which case its only action is to invoke another generative constructor.
   *
   * TODO(scheglov) review this later, there are no explicit "it is a
   * compile-time error" in specification. But it was added to the co19 and
   * there is same error for factories.
   *
   * https://code.google.com/p/dart/issues/detail?id=954
   */
  static const CompileTimeErrorCode RECURSIVE_CONSTRUCTOR_REDIRECT =
      const CompileTimeErrorCode('RECURSIVE_CONSTRUCTOR_REDIRECT',
          "Cycle in redirecting generative constructors");

  /**
   * 7.6.2 Factories: It is a compile-time error if a redirecting factory
   * constructor redirects to itself, either directly or indirectly via a
   * sequence of redirections.
   */
  static const CompileTimeErrorCode RECURSIVE_FACTORY_REDIRECT =
      const CompileTimeErrorCode('RECURSIVE_FACTORY_REDIRECT',
          "Cycle in redirecting factory constructors");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the interface of a
   * class <i>C</i> is a superinterface of itself.
   *
   * 8.1 Superinterfaces: It is a compile-time error if an interface is a
   * superinterface of itself.
   *
   * 7.9 Superclasses: It is a compile-time error if a class <i>C</i> is a
   * superclass of itself.
   *
   * Parameters:
   * 0: the name of the class that implements itself recursively
   * 1: a string representation of the implements loop
   */
  static const CompileTimeErrorCode RECURSIVE_INTERFACE_INHERITANCE =
      const CompileTimeErrorCode('RECURSIVE_INTERFACE_INHERITANCE',
          "'{0}' cannot be a superinterface of itself: {1}");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the interface of a
   * class <i>C</i> is a superinterface of itself.
   *
   * 8.1 Superinterfaces: It is a compile-time error if an interface is a
   * superinterface of itself.
   *
   * 7.9 Superclasses: It is a compile-time error if a class <i>C</i> is a
   * superclass of itself.
   *
   * Parameters:
   * 0: the name of the class that implements itself recursively
   */
  static const CompileTimeErrorCode
      RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS =
      const CompileTimeErrorCode(
          'RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS',
          "'{0}' cannot extend itself");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the interface of a
   * class <i>C</i> is a superinterface of itself.
   *
   * 8.1 Superinterfaces: It is a compile-time error if an interface is a
   * superinterface of itself.
   *
   * 7.9 Superclasses: It is a compile-time error if a class <i>C</i> is a
   * superclass of itself.
   *
   * Parameters:
   * 0: the name of the class that implements itself recursively
   */
  static const CompileTimeErrorCode
      RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS =
      const CompileTimeErrorCode(
          'RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS',
          "'{0}' cannot implement itself");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the interface of a
   * class <i>C</i> is a superinterface of itself.
   *
   * 8.1 Superinterfaces: It is a compile-time error if an interface is a
   * superinterface of itself.
   *
   * 7.9 Superclasses: It is a compile-time error if a class <i>C</i> is a
   * superclass of itself.
   *
   * Parameters:
   * 0: the name of the class that implements itself recursively
   */
  static const CompileTimeErrorCode
      RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_WITH =
      const CompileTimeErrorCode(
          'RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_WITH',
          "'{0}' cannot use itself as a mixin");

  /**
   * 7.6.2 Factories: It is a compile-time error if <i>k</i> is prefixed with
   * the const modifier but <i>k'</i> is not a constant constructor.
   */
  static const CompileTimeErrorCode REDIRECT_TO_MISSING_CONSTRUCTOR =
      const CompileTimeErrorCode('REDIRECT_TO_MISSING_CONSTRUCTOR',
          "The constructor '{0}' could not be found in '{1}'");

  /**
   * 7.6.2 Factories: It is a compile-time error if <i>k</i> is prefixed with
   * the const modifier but <i>k'</i> is not a constant constructor.
   */
  static const CompileTimeErrorCode REDIRECT_TO_NON_CLASS =
      const CompileTimeErrorCode('REDIRECT_TO_NON_CLASS',
          "The name '{0}' is not a type and cannot be used in a redirected constructor");

  /**
   * 7.6.2 Factories: It is a compile-time error if <i>k</i> is prefixed with
   * the const modifier but <i>k'</i> is not a constant constructor.
   */
  static const CompileTimeErrorCode REDIRECT_TO_NON_CONST_CONSTRUCTOR =
      const CompileTimeErrorCode('REDIRECT_TO_NON_CONST_CONSTRUCTOR',
          "Constant factory constructor cannot delegate to a non-constant constructor");

  /**
   * 7.6.1 Generative constructors: A generative constructor may be
   * <i>redirecting</i>, in which case its only action is to invoke another
   * generative constructor.
   */
  static const CompileTimeErrorCode REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR =
      const CompileTimeErrorCode('REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR',
          "The constructor '{0}' could not be found in '{1}'");

  /**
   * 7.6.1 Generative constructors: A generative constructor may be
   * <i>redirecting</i>, in which case its only action is to invoke another
   * generative constructor.
   */
  static const CompileTimeErrorCode
      REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR =
      const CompileTimeErrorCode(
          'REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR',
          "Generative constructor cannot redirect to a factory constructor");

  /**
   * 5 Variables: A local variable may only be referenced at a source code
   * location that is after its initializer, if any, is complete, or a
   * compile-time error occurs.
   */
  static const CompileTimeErrorCode REFERENCED_BEFORE_DECLARATION =
      const CompileTimeErrorCode('REFERENCED_BEFORE_DECLARATION',
          "Local variable '{0}' cannot be referenced before it is declared");

  /**
   * 12.8.1 Rethrow: It is a compile-time error if an expression of the form
   * <i>rethrow;</i> is not enclosed within a on-catch clause.
   */
  static const CompileTimeErrorCode RETHROW_OUTSIDE_CATCH =
      shared_messages.RETHROW_OUTSIDE_CATCH;

  /**
   * 13.12 Return: It is a compile-time error if a return statement of the form
   * <i>return e;</i> appears in a generative constructor.
   */
  static const CompileTimeErrorCode RETURN_IN_GENERATIVE_CONSTRUCTOR =
      shared_messages.RETURN_IN_GENERATIVE_CONSTRUCTOR;

  /**
   * 13.12 Return: It is a compile-time error if a return statement of the form
   * <i>return e;</i> appears in a generator function.
   */
  static const CompileTimeErrorCode RETURN_IN_GENERATOR =
      shared_messages.RETURN_IN_GENERATOR;

  /**
   * 14.1 Imports: It is a compile-time error if a prefix used in a deferred
   * import is used in another import clause.
   */
  static const CompileTimeErrorCode SHARED_DEFERRED_PREFIX =
      const CompileTimeErrorCode('SHARED_DEFERRED_PREFIX',
          "The prefix of a deferred import cannot be used in other import directives");

  /**
   * 12.15.4 Super Invocation: A super method invocation <i>i</i> has the form
   * <i>super.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>:
   * a<sub>n+1</sub>, &hellip; x<sub>n+k</sub>: a<sub>n+k</sub>)</i>. It is a
   * compile-time error if a super method invocation occurs in a top-level
   * function or variable initializer, in an instance variable initializer or
   * initializer list, in class Object, in a factory constructor, or in a static
   * method or variable initializer.
   */
  static const CompileTimeErrorCode SUPER_IN_INVALID_CONTEXT =
      const CompileTimeErrorCode(
          'SUPER_IN_INVALID_CONTEXT', "Invalid context for 'super' invocation");

  /**
   * 7.6.1 Generative Constructors: A generative constructor may be redirecting,
   * in which case its only action is to invoke another generative constructor.
   */
  static const CompileTimeErrorCode SUPER_IN_REDIRECTING_CONSTRUCTOR =
      const CompileTimeErrorCode('SUPER_IN_REDIRECTING_CONSTRUCTOR',
          "The redirecting constructor cannot have a 'super' initializer");

  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It
   * is a compile-time error if a generative constructor of class Object
   * includes a superinitializer.
   */
  static const CompileTimeErrorCode SUPER_INITIALIZER_IN_OBJECT =
      const CompileTimeErrorCode('SUPER_INITIALIZER_IN_OBJECT', "");

  /**
   * 12.11 Instance Creation: It is a static type warning if any of the type
   * arguments to a constructor of a generic type <i>G</i> invoked by a new
   * expression or a constant object expression are not subtypes of the bounds
   * of the corresponding formal type parameters of <i>G</i>.
   *
   * 12.11.1 New: If T is malformed a dynamic error occurs. In checked mode, if
   * T is mal-bounded a dynamic error occurs.
   *
   * 12.1 Constants: It is a compile-time error if evaluation of a compile-time
   * constant would raise an exception.
   *
   * Parameters:
   * 0: the name of the type used in the instance creation that should be
   *    limited by the bound as specified in the class declaration
   * 1: the name of the bounding type
   *
   * See [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS].
   */
  static const CompileTimeErrorCode TYPE_ARGUMENT_NOT_MATCHING_BOUNDS =
      const CompileTimeErrorCode(
          'TYPE_ARGUMENT_NOT_MATCHING_BOUNDS', "'{0}' does not extend '{1}'");

  /**
   * 15.3.1 Typedef: Any self reference, either directly, or recursively via
   * another typedef, is a compile time error.
   */
  static const CompileTimeErrorCode TYPE_ALIAS_CANNOT_REFERENCE_ITSELF =
      const CompileTimeErrorCode('TYPE_ALIAS_CANNOT_REFERENCE_ITSELF',
          "Type alias cannot reference itself directly or recursively via another typedef");

  /**
   * 12.11.2 Const: It is a compile-time error if <i>T</i> is not a class
   * accessible in the current scope, optionally followed by type arguments.
   */
  static const CompileTimeErrorCode UNDEFINED_CLASS =
      const CompileTimeErrorCode('UNDEFINED_CLASS', "Undefined class '{0}'");

  /**
   * 7.6.1 Generative Constructors: Let <i>C</i> be the class in which the
   * superinitializer appears and let <i>S</i> be the superclass of <i>C</i>.
   * Let <i>k</i> be a generative constructor. It is a compile-time error if
   * class <i>S</i> does not declare a generative constructor named <i>S</i>
   * (respectively <i>S.id</i>)
   */
  static const CompileTimeErrorCode UNDEFINED_CONSTRUCTOR_IN_INITIALIZER =
      const CompileTimeErrorCode('UNDEFINED_CONSTRUCTOR_IN_INITIALIZER',
          "The class '{0}' does not have a generative constructor '{1}'");

  /**
   * 7.6.1 Generative Constructors: Let <i>C</i> be the class in which the
   * superinitializer appears and let <i>S</i> be the superclass of <i>C</i>.
   * Let <i>k</i> be a generative constructor. It is a compile-time error if
   * class <i>S</i> does not declare a generative constructor named <i>S</i>
   * (respectively <i>S.id</i>)
   */
  static const CompileTimeErrorCode
      UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT = const CompileTimeErrorCode(
          'UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT',
          "The class '{0}' does not have a default generative constructor");

  /**
   * 12.14.2 Binding Actuals to Formals: Furthermore, each <i>q<sub>i</sub></i>,
   * <i>1<=i<=l</i>, must have a corresponding named parameter in the set
   * {<i>p<sub>n+1</sub></i> ... <i>p<sub>n+k</sub></i>} or a static warning
   * occurs.
   *
   * 12.11.2 Const: It is a compile-time error if evaluation of a constant
   * object results in an uncaught exception being thrown.
   *
   * Parameters:
   * 0: the name of the requested named parameter
   */
  static const CompileTimeErrorCode UNDEFINED_NAMED_PARAMETER =
      const CompileTimeErrorCode('UNDEFINED_NAMED_PARAMETER',
          "The named parameter '{0}' is not defined");

  /**
   * 14.2 Exports: It is a compile-time error if the compilation unit found at
   * the specified URI is not a library declaration.
   *
   * 14.1 Imports: It is a compile-time error if the compilation unit found at
   * the specified URI is not a library declaration.
   *
   * 14.3 Parts: It is a compile time error if the contents of the URI are not a
   * valid part declaration.
   *
   * Parameters:
   * 0: the URI pointing to a non-existent file
   *
   * See [INVALID_URI], [URI_HAS_NOT_BEEN_GENERATED].
   */
  static const CompileTimeErrorCode URI_DOES_NOT_EXIST =
      const CompileTimeErrorCode(
          'URI_DOES_NOT_EXIST', "Target of URI does not exist: '{0}'");

  /**
   * Just like [URI_DOES_NOT_EXIST], but used when the URI refers to a file that
   * is expected to be generated.
   *
   * Parameters:
   * 0: the URI pointing to a non-existent file
   *
   * See [INVALID_URI], [URI_DOES_NOT_EXIST].
   */
  static const CompileTimeErrorCode URI_HAS_NOT_BEEN_GENERATED =
      const CompileTimeErrorCode('URI_HAS_NOT_BEEN_GENERATED',
          "Target of URI has not been generated: '{0}'");

  /**
   * 14.1 Imports: It is a compile-time error if <i>x</i> is not a compile-time
   * constant, or if <i>x</i> involves string interpolation.
   *
   * 14.3 Parts: It is a compile-time error if <i>s</i> is not a compile-time
   * constant, or if <i>s</i> involves string interpolation.
   *
   * 14.5 URIs: It is a compile-time error if the string literal <i>x</i> that
   * describes a URI is not a compile-time constant, or if <i>x</i> involves
   * string interpolation.
   */
  static const CompileTimeErrorCode URI_WITH_INTERPOLATION =
      const CompileTimeErrorCode(
          'URI_WITH_INTERPOLATION', "URIs cannot use string interpolation");

  /**
   * 7.1.1 Operators: It is a compile-time error if the arity of the
   * user-declared operator []= is not 2. It is a compile time error if the
   * arity of a user-declared operator with one of the names: &lt;, &gt;, &lt;=,
   * &gt;=, ==, +, /, ~/, *, %, |, ^, &, &lt;&lt;, &gt;&gt;, [] is not 1. It is
   * a compile time error if the arity of the user-declared operator - is not 0
   * or 1. It is a compile time error if the arity of the user-declared operator
   * ~ is not 0.
   *
   * Parameters:
   * 0: the name of the declared operator
   * 1: the number of parameters expected
   * 2: the number of parameters found in the operator declaration
   */
  static const CompileTimeErrorCode WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR =
      const CompileTimeErrorCode('WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR',
          "Operator '{0}' should declare exactly {1} parameter(s), but {2} found");

  /**
   * 7.1.1 Operators: It is a compile time error if the arity of the
   * user-declared operator - is not 0 or 1.
   *
   * Parameters:
   * 0: the number of parameters found in the operator declaration
   */
  static const CompileTimeErrorCode
      WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS =
      const CompileTimeErrorCode(
          'WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS',
          "Operator '-' should declare 0 or 1 parameter, but {0} found");

  /**
   * 7.3 Setters: It is a compile-time error if a setter's formal parameter list
   * does not include exactly one required formal parameter <i>p</i>.
   */
  static const CompileTimeErrorCode WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER =
      const CompileTimeErrorCode('WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER',
          "Setters should declare exactly one required parameter");

  /**
   * ?? Yield: It is a compile-time error if a yield statement appears in a
   * function that is not a generator function.
   */
  static const CompileTimeErrorCode YIELD_EACH_IN_NON_GENERATOR =
      const CompileTimeErrorCode('YIELD_EACH_IN_NON_GENERATOR',
          "Yield-each statements must be in a generator function (one marked with either 'async*' or 'sync*')");

  /**
   * ?? Yield: It is a compile-time error if a yield statement appears in a
   * function that is not a generator function.
   */
  static const CompileTimeErrorCode YIELD_IN_NON_GENERATOR =
      const CompileTimeErrorCode('YIELD_IN_NON_GENERATOR',
          "Yield statements must be in a generator function (one marked with either 'async*' or 'sync*')");

  /**
   * Initialize a newly created error code to have the given [name]. The message
   * associated with the error will be created from the given [message]
   * template. The correction associated with the error will be created from the
   * given [correction] template.
   */
  const CompileTimeErrorCode(String name, String message, [String correction])
      : super(name, message, correction);

  @override
  ErrorSeverity get errorSeverity => ErrorType.COMPILE_TIME_ERROR.severity;

  @override
  ErrorType get type => ErrorType.COMPILE_TIME_ERROR;
}

/**
 * An error code associated with an [AnalysisError].
 *
 * Generally, we want to provide messages that consist of three sentences. From
 * the user's perspective these sentences should explain:
 * 1. what is wrong,
 * 2. why is it wrong, and
 * 3. how do I fix it.
 * However, we combine the first two in the [message] and the last in the
 * [correction].
 */
abstract class ErrorCode {
  /**
   * Engine error code values.
   */
  static const List<ErrorCode> values = const [
    //
    // Manually generated.  FWIW, this get's you most of the way there:
    //
    // > grep 'static const .*Code' (error.dart|parser|scanner.dart)
    //     | awk '{print $3"."$4","}'
    //
    // error.dart:
    //
    AnalysisOptionsErrorCode.PARSE_ERROR,
    AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUES,
    AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUE,
    AnalysisOptionsWarningCode.UNSUPPORTED_VALUE,
    AnalysisOptionsWarningCode.UNRECOGNIZED_ERROR_CODE,
    CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH,
    CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
    CheckedModeCompileTimeErrorCode.CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE,
    CheckedModeCompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE,
    CheckedModeCompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE,
    CheckedModeCompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE,
    CheckedModeCompileTimeErrorCode.VARIABLE_TYPE_MISMATCH,
    CompileTimeErrorCode.ACCESS_PRIVATE_ENUM_FIELD,
    CompileTimeErrorCode.AMBIGUOUS_EXPORT,
    CompileTimeErrorCode.ANNOTATION_WITH_NON_CLASS,
    CompileTimeErrorCode.ARGUMENT_DEFINITION_TEST_NON_PARAMETER,
    CompileTimeErrorCode.ASYNC_FOR_IN_WRONG_CONTEXT,
    CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT,
    CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE,
    CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME,
    CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME,
    CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME,
    CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS,
    CompileTimeErrorCode.COMPILE_TIME_CONSTANT_RAISES_EXCEPTION,
    CompileTimeErrorCode.CONFLICTING_GETTER_AND_METHOD,
    CompileTimeErrorCode.CONFLICTING_METHOD_AND_GETTER,
    CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_FIELD,
    CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_METHOD,
    CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_CLASS,
    CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER,
    CompileTimeErrorCode.CONST_CONSTRUCTOR_THROWS_EXCEPTION,
    CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST,
    CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN,
    CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER,
    CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD,
    CompileTimeErrorCode.CONST_DEFERRED_CLASS,
    CompileTimeErrorCode.CONST_FORMAL_PARAMETER,
    CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE,
    CompileTimeErrorCode
        .CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY,
    CompileTimeErrorCode.CONST_INSTANCE_FIELD,
    CompileTimeErrorCode.CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS,
    CompileTimeErrorCode.CONST_NOT_INITIALIZED,
    CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL,
    CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING,
    CompileTimeErrorCode.CONST_EVAL_TYPE_INT,
    CompileTimeErrorCode.CONST_EVAL_TYPE_NUM,
    CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
    CompileTimeErrorCode.CONST_EVAL_THROWS_IDBZE,
    CompileTimeErrorCode.CONST_WITH_INVALID_TYPE_PARAMETERS,
    CompileTimeErrorCode.CONST_WITH_NON_CONST,
    CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT,
    CompileTimeErrorCode.CONST_WITH_NON_TYPE,
    CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS,
    CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR,
    CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT,
    CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS,
    CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPED_PARAMETER,
    CompileTimeErrorCode.DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR,
    CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT,
    CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME,
    CompileTimeErrorCode.DUPLICATE_DEFINITION,
    CompileTimeErrorCode.DUPLICATE_DEFINITION_INHERITANCE,
    CompileTimeErrorCode.DUPLICATE_NAMED_ARGUMENT,
    CompileTimeErrorCode.EXPORT_INTERNAL_LIBRARY,
    CompileTimeErrorCode.EXPORT_OF_NON_LIBRARY,
    CompileTimeErrorCode.EXTENDS_ENUM,
    CompileTimeErrorCode.EXTENDS_NON_CLASS,
    CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS,
    CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS,
    CompileTimeErrorCode.EXTRA_ARGUMENT_TO_ASSERT,
    CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS,
    CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS,
    CompileTimeErrorCode.FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER,
    CompileTimeErrorCode.FINAL_INITIALIZED_MULTIPLE_TIMES,
    CompileTimeErrorCode.FIELD_INITIALIZER_FACTORY_CONSTRUCTOR,
    CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR,
    CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR,
    CompileTimeErrorCode.GETTER_AND_METHOD_WITH_SAME_NAME,
    CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS,
    CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS,
    CompileTimeErrorCode.IMPLEMENTS_DYNAMIC,
    CompileTimeErrorCode.IMPLEMENTS_ENUM,
    CompileTimeErrorCode.IMPLEMENTS_NON_CLASS,
    CompileTimeErrorCode.IMPLEMENTS_REPEATED,
    CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS,
    CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER,
    CompileTimeErrorCode.IMPORT_INTERNAL_LIBRARY,
    CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY,
    CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES,
    CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD,
    CompileTimeErrorCode.INITIALIZER_FOR_STATIC_FIELD,
    CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD,
    CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_STATIC_FIELD,
    CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_FACTORY,
    CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC,
    CompileTimeErrorCode.INSTANTIATE_ENUM,
    CompileTimeErrorCode.INVALID_ANNOTATION,
    CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY,
    CompileTimeErrorCode.INVALID_IDENTIFIER_IN_ASYNC,
    CompileTimeErrorCode.INVALID_MODIFIER_ON_CONSTRUCTOR,
    CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER,
    CompileTimeErrorCode.INVALID_CONSTANT,
    CompileTimeErrorCode.INVALID_CONSTRUCTOR_NAME,
    CompileTimeErrorCode.INVALID_FACTORY_NAME_NOT_A_CLASS,
    CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS,
    CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_LIST,
    CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP,
    CompileTimeErrorCode.INVALID_URI,
    CompileTimeErrorCode.LABEL_IN_OUTER_SCOPE,
    CompileTimeErrorCode.LABEL_UNDEFINED,
    CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME,
    CompileTimeErrorCode.METHOD_AND_GETTER_WITH_SAME_NAME,
    CompileTimeErrorCode.MISSING_CONST_IN_LIST_LITERAL,
    CompileTimeErrorCode.MISSING_CONST_IN_MAP_LITERAL,
    CompileTimeErrorCode.MIXIN_DECLARES_CONSTRUCTOR,
    CompileTimeErrorCode.MIXIN_DEFERRED_CLASS,
    CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS,
    CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT,
    CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS,
    CompileTimeErrorCode.MIXIN_OF_ENUM,
    CompileTimeErrorCode.MIXIN_OF_NON_CLASS,
    CompileTimeErrorCode.MIXIN_REFERENCES_SUPER,
    CompileTimeErrorCode.MIXIN_WITH_NON_CLASS_SUPERCLASS,
    CompileTimeErrorCode.MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS,
    CompileTimeErrorCode.MULTIPLE_SUPER_INITIALIZERS,
    CompileTimeErrorCode.NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS,
    CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT,
    CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT,
    CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT,
    CompileTimeErrorCode.NON_CONSTANT_CASE_EXPRESSION,
    CompileTimeErrorCode.NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY,
    CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE,
    CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY,
    CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT,
    CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY,
    CompileTimeErrorCode.NON_CONSTANT_MAP_KEY,
    CompileTimeErrorCode.NON_CONSTANT_MAP_KEY_FROM_DEFERRED_LIBRARY,
    CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE,
    CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY,
    CompileTimeErrorCode.NON_CONSTANT_ANNOTATION_CONSTRUCTOR,
    CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER,
    CompileTimeErrorCode
        .NON_CONSTANT_VALUE_IN_INITIALIZER_FROM_DEFERRED_LIBRARY,
    CompileTimeErrorCode.NOT_ENOUGH_REQUIRED_ARGUMENTS,
    CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR,
    CompileTimeErrorCode.OBJECT_CANNOT_EXTEND_ANOTHER_CLASS,
    CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR,
    CompileTimeErrorCode.PART_OF_NON_PART,
    CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER,
    CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT,
    CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER,
    CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT,
    CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT,
    CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
    CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
    CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS,
    CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS,
    CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_WITH,
    CompileTimeErrorCode.REDIRECT_TO_MISSING_CONSTRUCTOR,
    CompileTimeErrorCode.REDIRECT_TO_NON_CLASS,
    CompileTimeErrorCode.REDIRECT_TO_NON_CONST_CONSTRUCTOR,
    CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR,
    CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR,
    CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION,
    CompileTimeErrorCode.RETHROW_OUTSIDE_CATCH,
    CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR,
    CompileTimeErrorCode.RETURN_IN_GENERATOR,
    CompileTimeErrorCode.SHARED_DEFERRED_PREFIX,
    CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT,
    CompileTimeErrorCode.SUPER_IN_REDIRECTING_CONSTRUCTOR,
    CompileTimeErrorCode.SUPER_INITIALIZER_IN_OBJECT,
    CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS,
    CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF,
    CompileTimeErrorCode.UNDEFINED_CLASS,
    CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER,
    CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT,
    CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER,
    CompileTimeErrorCode.URI_DOES_NOT_EXIST,
    CompileTimeErrorCode.URI_WITH_INTERPOLATION,
    CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR,
    CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS,
    CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER,
    CompileTimeErrorCode.YIELD_EACH_IN_NON_GENERATOR,
    CompileTimeErrorCode.YIELD_IN_NON_GENERATOR,
    HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
    HintCode.CAN_BE_NULL_AFTER_NULL_AWARE,
    HintCode.DEAD_CODE,
    HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH,
    HintCode.DEAD_CODE_ON_CATCH_SUBTYPE,
    HintCode.DEPRECATED_MEMBER_USE,
    HintCode.DUPLICATE_IMPORT,
    HintCode.DIVISION_OPTIMIZATION,
    HintCode.INVALID_FACTORY_ANNOTATION,
    HintCode.INVALID_FACTORY_METHOD_DECL,
    HintCode.INVALID_FACTORY_METHOD_IMPL,
    HintCode.IS_DOUBLE,
    HintCode.IS_INT,
    HintCode.IS_NOT_DOUBLE,
    HintCode.IS_NOT_INT,
    HintCode.IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION,
    HintCode.INVALID_ASSIGNMENT,
    HintCode.INVALID_USE_OF_PROTECTED_MEMBER,
    HintCode.MISSING_JS_LIB_ANNOTATION,
    HintCode.MISSING_REQUIRED_PARAM,
    HintCode.MISSING_REQUIRED_PARAM_WITH_DETAILS,
    HintCode.MISSING_RETURN,
    HintCode.NULL_AWARE_IN_CONDITION,
    HintCode.OVERRIDE_ON_NON_OVERRIDING_GETTER,
    HintCode.OVERRIDE_ON_NON_OVERRIDING_FIELD,
    HintCode.OVERRIDE_ON_NON_OVERRIDING_METHOD,
    HintCode.OVERRIDE_ON_NON_OVERRIDING_SETTER,
    HintCode.OVERRIDE_EQUALS_BUT_NOT_HASH_CODE,
    HintCode.TYPE_CHECK_IS_NOT_NULL,
    HintCode.TYPE_CHECK_IS_NULL,
    HintCode.UNDEFINED_GETTER,
    HintCode.UNDEFINED_HIDDEN_NAME,
    HintCode.UNDEFINED_METHOD,
    HintCode.UNDEFINED_OPERATOR,
    HintCode.UNDEFINED_SETTER,
    HintCode.UNDEFINED_SHOWN_NAME,
    HintCode.UNNECESSARY_CAST,
    HintCode.UNNECESSARY_NO_SUCH_METHOD,
    HintCode.UNNECESSARY_TYPE_CHECK_FALSE,
    HintCode.UNNECESSARY_TYPE_CHECK_TRUE,
    HintCode.UNUSED_ELEMENT,
    HintCode.UNUSED_FIELD,
    HintCode.UNUSED_IMPORT,
    HintCode.UNUSED_CATCH_CLAUSE,
    HintCode.UNUSED_CATCH_STACK,
    HintCode.UNUSED_LOCAL_VARIABLE,
    HintCode.UNUSED_SHOWN_NAME,
    HintCode.USE_OF_VOID_RESULT,
    HintCode.FILE_IMPORT_INSIDE_LIB_REFERENCES_FILE_OUTSIDE,
    HintCode.FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE,
    HintCode.PACKAGE_IMPORT_CONTAINS_DOT_DOT,
    HtmlErrorCode.PARSE_ERROR,
    HtmlWarningCode.INVALID_URI,
    HtmlWarningCode.URI_DOES_NOT_EXIST,
    StaticTypeWarningCode.EXPECTED_ONE_LIST_TYPE_ARGUMENTS,
    StaticTypeWarningCode.EXPECTED_TWO_MAP_TYPE_ARGUMENTS,
    StaticTypeWarningCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE,
    StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE,
    StaticTypeWarningCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE,
    StaticTypeWarningCode.INACCESSIBLE_SETTER,
    StaticTypeWarningCode.INCONSISTENT_METHOD_INHERITANCE,
    StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER,
    StaticTypeWarningCode.INVALID_ASSIGNMENT,
    StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION,
    StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION,
    StaticTypeWarningCode.NON_BOOL_CONDITION,
    StaticTypeWarningCode.NON_BOOL_EXPRESSION,
    StaticTypeWarningCode.NON_BOOL_NEGATION_EXPRESSION,
    StaticTypeWarningCode.NON_BOOL_OPERAND,
    StaticTypeWarningCode.NON_NULLABLE_FIELD_NOT_INITIALIZED,
    StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT,
    StaticTypeWarningCode.RETURN_OF_INVALID_TYPE,
    StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS,
    StaticTypeWarningCode.TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND,
    StaticTypeWarningCode.UNDEFINED_ENUM_CONSTANT,
    StaticTypeWarningCode.UNDEFINED_FUNCTION,
    StaticTypeWarningCode.UNDEFINED_GETTER,
    StaticTypeWarningCode.UNDEFINED_METHOD,
    StaticTypeWarningCode.UNDEFINED_METHOD_WITH_CONSTRUCTOR,
    StaticTypeWarningCode.UNDEFINED_OPERATOR,
    StaticTypeWarningCode.UNDEFINED_SETTER,
    StaticTypeWarningCode.UNDEFINED_SUPER_GETTER,
    StaticTypeWarningCode.UNDEFINED_SUPER_METHOD,
    StaticTypeWarningCode.UNDEFINED_SUPER_OPERATOR,
    StaticTypeWarningCode.UNDEFINED_SUPER_SETTER,
    StaticTypeWarningCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER,
    StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS,
    StaticTypeWarningCode.YIELD_OF_INVALID_TYPE,
    StaticTypeWarningCode.FOR_IN_OF_INVALID_TYPE,
    StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE,
    StaticWarningCode.AMBIGUOUS_IMPORT,
    StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
    StaticWarningCode.ASSIGNMENT_TO_CONST,
    StaticWarningCode.ASSIGNMENT_TO_FINAL,
    StaticWarningCode.ASSIGNMENT_TO_FINAL_NO_SETTER,
    StaticWarningCode.ASSIGNMENT_TO_FUNCTION,
    StaticWarningCode.ASSIGNMENT_TO_METHOD,
    StaticWarningCode.ASSIGNMENT_TO_TYPE,
    StaticWarningCode.CASE_BLOCK_NOT_TERMINATED,
    StaticWarningCode.CAST_TO_NON_TYPE,
    StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER,
    StaticWarningCode.CONFLICTING_DART_IMPORT,
    StaticWarningCode.CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER,
    StaticWarningCode.CONFLICTING_INSTANCE_METHOD_SETTER,
    StaticWarningCode.CONFLICTING_INSTANCE_METHOD_SETTER2,
    StaticWarningCode.CONFLICTING_INSTANCE_SETTER_AND_SUPERCLASS_MEMBER,
    StaticWarningCode.CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER,
    StaticWarningCode.CONFLICTING_STATIC_SETTER_AND_INSTANCE_MEMBER,
    StaticWarningCode.CONST_WITH_ABSTRACT_CLASS,
    StaticWarningCode.EQUAL_KEYS_IN_MAP,
    StaticWarningCode.EXPORT_DUPLICATED_LIBRARY_NAMED,
    StaticWarningCode.EXTRA_POSITIONAL_ARGUMENTS,
    StaticWarningCode.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION,
    StaticWarningCode.FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR,
    StaticWarningCode.FIELD_INITIALIZER_NOT_ASSIGNABLE,
    StaticWarningCode.FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE,
    StaticWarningCode.FINAL_NOT_INITIALIZED,
    StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_1,
    StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_2,
    StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS,
    StaticWarningCode.FUNCTION_WITHOUT_CALL,
    StaticWarningCode.IMPORT_DUPLICATED_LIBRARY_NAMED,
    StaticWarningCode.IMPORT_OF_NON_LIBRARY,
    StaticWarningCode.INCONSISTENT_METHOD_INHERITANCE_GETTER_AND_METHOD,
    StaticWarningCode.INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC,
    StaticWarningCode.INVALID_GETTER_OVERRIDE_RETURN_TYPE,
    StaticWarningCode.INVALID_METHOD_OVERRIDE_NAMED_PARAM_TYPE,
    StaticWarningCode.INVALID_METHOD_OVERRIDE_TYPE_PARAMETERS,
    StaticWarningCode.INVALID_METHOD_OVERRIDE_TYPE_PARAMETER_BOUND,
    StaticWarningCode.INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE,
    StaticWarningCode.INVALID_METHOD_OVERRIDE_OPTIONAL_PARAM_TYPE,
    StaticWarningCode.INVALID_METHOD_OVERRIDE_RETURN_TYPE,
    StaticWarningCode.INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED,
    StaticWarningCode.INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL,
    StaticWarningCode.INVALID_OVERRIDE_NAMED,
    StaticWarningCode.INVALID_OVERRIDE_POSITIONAL,
    StaticWarningCode.INVALID_OVERRIDE_REQUIRED,
    StaticWarningCode.INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE,
    StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE,
    StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE,
    StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE,
    StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES,
    StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES_FROM_SUPERTYPE,
    StaticWarningCode.MIXED_RETURN_TYPES,
    StaticWarningCode.NEW_WITH_ABSTRACT_CLASS,
    StaticWarningCode.NEW_WITH_INVALID_TYPE_PARAMETERS,
    StaticWarningCode.NEW_WITH_NON_TYPE,
    StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR,
    StaticWarningCode.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT,
    StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS,
    StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR,
    StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
    StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE,
    StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO,
    StaticWarningCode.NON_TYPE_IN_CATCH_CLAUSE,
    StaticWarningCode.NON_VOID_RETURN_FOR_OPERATOR,
    StaticWarningCode.NON_VOID_RETURN_FOR_SETTER,
    StaticWarningCode.NOT_A_TYPE,
    StaticWarningCode.NOT_ENOUGH_REQUIRED_ARGUMENTS,
    StaticWarningCode.PART_OF_DIFFERENT_LIBRARY,
    StaticWarningCode.REDIRECT_TO_INVALID_FUNCTION_TYPE,
    StaticWarningCode.REDIRECT_TO_INVALID_RETURN_TYPE,
    StaticWarningCode.REDIRECT_TO_MISSING_CONSTRUCTOR,
    StaticWarningCode.REDIRECT_TO_NON_CLASS,
    StaticWarningCode.RETURN_WITHOUT_VALUE,
    StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER,
    StaticWarningCode.SWITCH_EXPRESSION_NOT_ASSIGNABLE,
    StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS,
    StaticWarningCode.TYPE_TEST_WITH_NON_TYPE,
    StaticWarningCode.TYPE_TEST_WITH_UNDEFINED_NAME,
    StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC,
    StaticWarningCode.UNDEFINED_CLASS,
    StaticWarningCode.UNDEFINED_CLASS_BOOLEAN,
    StaticWarningCode.UNDEFINED_GETTER,
    StaticWarningCode.UNDEFINED_IDENTIFIER,
    StaticWarningCode.UNDEFINED_NAMED_PARAMETER,
    StaticWarningCode.UNDEFINED_SETTER,
    StaticWarningCode.UNDEFINED_STATIC_METHOD_OR_GETTER,
    StaticWarningCode.UNDEFINED_SUPER_GETTER,
    StaticWarningCode.UNDEFINED_SUPER_SETTER,
    StaticWarningCode.VOID_RETURN_FOR_GETTER,
    StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH,
    StrongModeCode.ASSIGNMENT_CAST,
    StrongModeCode.DOWN_CAST_COMPOSITE,
    StrongModeCode.DOWN_CAST_IMPLICIT,
    StrongModeCode.DYNAMIC_CAST,
    StrongModeCode.DYNAMIC_INVOKE,
    StrongModeCode.IMPLICIT_DYNAMIC_FIELD,
    StrongModeCode.IMPLICIT_DYNAMIC_FUNCTION,
    StrongModeCode.IMPLICIT_DYNAMIC_INVOKE,
    StrongModeCode.IMPLICIT_DYNAMIC_LIST_LITERAL,
    StrongModeCode.IMPLICIT_DYNAMIC_MAP_LITERAL,
    StrongModeCode.IMPLICIT_DYNAMIC_METHOD,
    StrongModeCode.IMPLICIT_DYNAMIC_PARAMETER,
    StrongModeCode.IMPLICIT_DYNAMIC_RETURN,
    StrongModeCode.IMPLICIT_DYNAMIC_TYPE,
    StrongModeCode.IMPLICIT_DYNAMIC_VARIABLE,
    StrongModeCode.INFERRED_TYPE,
    StrongModeCode.INFERRED_TYPE_ALLOCATION,
    StrongModeCode.INFERRED_TYPE_CLOSURE,
    StrongModeCode.INFERRED_TYPE_LITERAL,
    StrongModeCode.INVALID_FIELD_OVERRIDE,
    StrongModeCode.INVALID_METHOD_OVERRIDE,
    StrongModeCode.INVALID_METHOD_OVERRIDE_FROM_BASE,
    StrongModeCode.INVALID_METHOD_OVERRIDE_FROM_MIXIN,
    StrongModeCode.INVALID_PARAMETER_DECLARATION,
    StrongModeCode.INVALID_SUPER_INVOCATION,
    StrongModeCode.NON_GROUND_TYPE_CHECK_INFO,
    StrongModeCode.STATIC_TYPE_ERROR,
    StrongModeCode.UNSAFE_BLOCK_CLOSURE_INFERENCE,

    TodoCode.TODO,

    //
    // parser.dart:
    //
    ParserErrorCode.ABSTRACT_CLASS_MEMBER,
    ParserErrorCode.ABSTRACT_ENUM,
    ParserErrorCode.ABSTRACT_STATIC_METHOD,
    ParserErrorCode.ABSTRACT_TOP_LEVEL_FUNCTION,
    ParserErrorCode.ABSTRACT_TOP_LEVEL_VARIABLE,
    ParserErrorCode.ABSTRACT_TYPEDEF,
    ParserErrorCode.ANNOTATION_ON_ENUM_CONSTANT,
    ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER,
    ParserErrorCode.ASYNC_NOT_SUPPORTED,
    ParserErrorCode.BREAK_OUTSIDE_OF_LOOP,
    ParserErrorCode.CLASS_IN_CLASS,
    ParserErrorCode.COLON_IN_PLACE_OF_IN,
    ParserErrorCode.CONST_AND_FINAL,
    ParserErrorCode.CONST_AND_VAR,
    ParserErrorCode.CONST_CLASS,
    ParserErrorCode.CONST_CONSTRUCTOR_WITH_BODY,
    ParserErrorCode.CONST_ENUM,
    ParserErrorCode.CONST_FACTORY,
    ParserErrorCode.CONST_METHOD,
    ParserErrorCode.CONST_TYPEDEF,
    ParserErrorCode.CONSTRUCTOR_WITH_RETURN_TYPE,
    ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP,
    ParserErrorCode.CONTINUE_WITHOUT_LABEL_IN_CASE,
    ParserErrorCode.DEPRECATED_CLASS_TYPE_ALIAS,
    ParserErrorCode.DIRECTIVE_AFTER_DECLARATION,
    ParserErrorCode.DUPLICATE_LABEL_IN_SWITCH_STATEMENT,
    ParserErrorCode.DUPLICATED_MODIFIER,
    ParserErrorCode.EMPTY_ENUM_BODY,
    ParserErrorCode.ENUM_IN_CLASS,
    ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND,
    ParserErrorCode.EXPECTED_CASE_OR_DEFAULT,
    ParserErrorCode.EXPECTED_CLASS_MEMBER,
    ParserErrorCode.EXPECTED_EXECUTABLE,
    ParserErrorCode.EXPECTED_LIST_OR_MAP_LITERAL,
    ParserErrorCode.EXPECTED_STRING_LITERAL,
    ParserErrorCode.EXPECTED_TOKEN,
    ParserErrorCode.EXPECTED_TYPE_NAME,
    ParserErrorCode.EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE,
    ParserErrorCode.EXTERNAL_AFTER_CONST,
    ParserErrorCode.EXTERNAL_AFTER_FACTORY,
    ParserErrorCode.EXTERNAL_AFTER_STATIC,
    ParserErrorCode.EXTERNAL_CLASS,
    ParserErrorCode.EXTERNAL_CONSTRUCTOR_WITH_BODY,
    ParserErrorCode.EXTERNAL_ENUM,
    ParserErrorCode.EXTERNAL_FIELD,
    ParserErrorCode.EXTERNAL_GETTER_WITH_BODY,
    ParserErrorCode.EXTERNAL_METHOD_WITH_BODY,
    ParserErrorCode.EXTERNAL_OPERATOR_WITH_BODY,
    ParserErrorCode.EXTERNAL_SETTER_WITH_BODY,
    ParserErrorCode.EXTERNAL_TYPEDEF,
    ParserErrorCode.FACTORY_TOP_LEVEL_DECLARATION,
    ParserErrorCode.FACTORY_WITH_INITIALIZERS,
    ParserErrorCode.FACTORY_WITHOUT_BODY,
    ParserErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR,
    ParserErrorCode.FINAL_AND_VAR,
    ParserErrorCode.FINAL_CLASS,
    ParserErrorCode.FINAL_CONSTRUCTOR,
    ParserErrorCode.FINAL_ENUM,
    ParserErrorCode.FINAL_METHOD,
    ParserErrorCode.FINAL_TYPEDEF,
    ParserErrorCode.FUNCTION_TYPED_PARAMETER_VAR,
    ParserErrorCode.GETTER_IN_FUNCTION,
    ParserErrorCode.GETTER_WITH_PARAMETERS,
    ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE,
    ParserErrorCode.IMPLEMENTS_BEFORE_EXTENDS,
    ParserErrorCode.IMPLEMENTS_BEFORE_WITH,
    ParserErrorCode.IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE,
    ParserErrorCode.INITIALIZED_VARIABLE_IN_FOR_EACH,
    ParserErrorCode.INVALID_AWAIT_IN_FOR,
    ParserErrorCode.INVALID_CODE_POINT,
    ParserErrorCode.INVALID_COMMENT_REFERENCE,
    ParserErrorCode.INVALID_HEX_ESCAPE,
    ParserErrorCode.INVALID_LITERAL_IN_CONFIGURATION,
    ParserErrorCode.INVALID_OPERATOR,
    ParserErrorCode.INVALID_OPERATOR_FOR_SUPER,
    ParserErrorCode.INVALID_STAR_AFTER_ASYNC,
    ParserErrorCode.INVALID_SYNC,
    ParserErrorCode.INVALID_UNICODE_ESCAPE,
    ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST,
    ParserErrorCode.LOCAL_FUNCTION_DECLARATION_MODIFIER,
    ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR,
    ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER,
    ParserErrorCode.MISSING_CATCH_OR_FINALLY,
    ParserErrorCode.MISSING_CLASS_BODY,
    ParserErrorCode.MISSING_CLOSING_PARENTHESIS,
    ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE,
    ParserErrorCode.MISSING_ENUM_BODY,
    ParserErrorCode.MISSING_EXPRESSION_IN_INITIALIZER,
    ParserErrorCode.MISSING_EXPRESSION_IN_THROW,
    ParserErrorCode.MISSING_FUNCTION_BODY,
    ParserErrorCode.MISSING_FUNCTION_PARAMETERS,
    ParserErrorCode.MISSING_METHOD_PARAMETERS,
    ParserErrorCode.MISSING_GET,
    ParserErrorCode.MISSING_IDENTIFIER,
    ParserErrorCode.MISSING_INITIALIZER,
    ParserErrorCode.MISSING_KEYWORD_OPERATOR,
    ParserErrorCode.MISSING_NAME_IN_LIBRARY_DIRECTIVE,
    ParserErrorCode.MISSING_NAME_IN_PART_OF_DIRECTIVE,
    ParserErrorCode.MISSING_PREFIX_IN_DEFERRED_IMPORT,
    ParserErrorCode.MISSING_STAR_AFTER_SYNC,
    ParserErrorCode.MISSING_STATEMENT,
    ParserErrorCode.MISSING_TERMINATOR_FOR_PARAMETER_GROUP,
    ParserErrorCode.MISSING_TYPEDEF_PARAMETERS,
    ParserErrorCode.MISSING_VARIABLE_IN_FOR_EACH,
    ParserErrorCode.MIXED_PARAMETER_GROUPS,
    ParserErrorCode.MULTIPLE_EXTENDS_CLAUSES,
    ParserErrorCode.MULTIPLE_IMPLEMENTS_CLAUSES,
    ParserErrorCode.MULTIPLE_LIBRARY_DIRECTIVES,
    ParserErrorCode.MULTIPLE_NAMED_PARAMETER_GROUPS,
    ParserErrorCode.MULTIPLE_PART_OF_DIRECTIVES,
    ParserErrorCode.MULTIPLE_POSITIONAL_PARAMETER_GROUPS,
    ParserErrorCode.MULTIPLE_VARIABLES_IN_FOR_EACH,
    ParserErrorCode.MULTIPLE_WITH_CLAUSES,
    ParserErrorCode.NAMED_FUNCTION_EXPRESSION,
    ParserErrorCode.NAMED_PARAMETER_OUTSIDE_GROUP,
    ParserErrorCode.NATIVE_CLAUSE_IN_NON_SDK_CODE,
    ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE,
    ParserErrorCode.NON_CONSTRUCTOR_FACTORY,
    ParserErrorCode.NON_IDENTIFIER_LIBRARY_NAME,
    ParserErrorCode.NON_PART_OF_DIRECTIVE_IN_PART,
    ParserErrorCode.NON_STRING_LITERAL_AS_URI,
    ParserErrorCode.NON_USER_DEFINABLE_OPERATOR,
    ParserErrorCode.NORMAL_BEFORE_OPTIONAL_PARAMETERS,
    ParserErrorCode.POSITIONAL_AFTER_NAMED_ARGUMENT,
    ParserErrorCode.POSITIONAL_PARAMETER_OUTSIDE_GROUP,
    ParserErrorCode.REDIRECTING_CONSTRUCTOR_WITH_BODY,
    ParserErrorCode.REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR,
    ParserErrorCode.SETTER_IN_FUNCTION,
    ParserErrorCode.STATIC_AFTER_CONST,
    ParserErrorCode.STATIC_AFTER_FINAL,
    ParserErrorCode.STATIC_AFTER_VAR,
    ParserErrorCode.STATIC_CONSTRUCTOR,
    ParserErrorCode.STATIC_GETTER_WITHOUT_BODY,
    ParserErrorCode.STATIC_OPERATOR,
    ParserErrorCode.STATIC_SETTER_WITHOUT_BODY,
    ParserErrorCode.STATIC_TOP_LEVEL_DECLARATION,
    ParserErrorCode.SWITCH_HAS_CASE_AFTER_DEFAULT_CASE,
    ParserErrorCode.SWITCH_HAS_MULTIPLE_DEFAULT_CASES,
    ParserErrorCode.TOP_LEVEL_OPERATOR,
    ParserErrorCode.TYPEDEF_IN_CLASS,
    ParserErrorCode.UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP,
    ParserErrorCode.UNEXPECTED_TOKEN,
    ParserErrorCode.WITH_BEFORE_EXTENDS,
    ParserErrorCode.WITH_WITHOUT_EXTENDS,
    ParserErrorCode.WRONG_SEPARATOR_FOR_NAMED_PARAMETER,
    ParserErrorCode.WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER,
    ParserErrorCode.WRONG_TERMINATOR_FOR_PARAMETER_GROUP,
    ParserErrorCode.VAR_AND_TYPE,
    ParserErrorCode.VAR_AS_TYPE_NAME,
    ParserErrorCode.VAR_CLASS,
    ParserErrorCode.VAR_ENUM,
    ParserErrorCode.VAR_RETURN_TYPE,
    ParserErrorCode.VAR_TYPEDEF,
    ParserErrorCode.VOID_PARAMETER,
    ParserErrorCode.VOID_VARIABLE,

    //
    // scanner.dart:
    //
    ScannerErrorCode.ILLEGAL_CHARACTER,
    ScannerErrorCode.MISSING_DIGIT,
    ScannerErrorCode.MISSING_HEX_DIGIT,
    ScannerErrorCode.MISSING_QUOTE,
    ScannerErrorCode.UNABLE_GET_CONTENT,
    ScannerErrorCode.UNTERMINATED_MULTI_LINE_COMMENT,
    ScannerErrorCode.UNTERMINATED_STRING_LITERAL,
  ];

  /**
   * The lazy initialized map from [uniqueName] to the [ErrorCode] instance.
   */
  static HashMap<String, ErrorCode> _uniqueNameToCodeMap;

  /**
   * An empty list of error codes.
   */
  static const List<ErrorCode> EMPTY_LIST = const <ErrorCode>[];

  /**
   * The name of the error code.
   */
  final String name;

  /**
   * The template used to create the message to be displayed for this error. The
   * message should indicate what is wrong and why it is wrong.
   */
  final String message;

  /**
   * The template used to create the correction to be displayed for this error,
   * or `null` if there is no correction information for this error. The
   * correction should indicate how the user can fix the error.
   */
  final String correction;

  /**
   * Initialize a newly created error code to have the given [name]. The message
   * associated with the error will be created from the given [message]
   * template. The correction associated with the error will be created from the
   * given [correction] template.
   */
  const ErrorCode(this.name, this.message, [this.correction]);

  /**
   * The severity of the error.
   */
  ErrorSeverity get errorSeverity;

  /**
   * The type of the error.
   */
  ErrorType get type;

  /**
   * The unique name of this error code.
   */
  String get uniqueName => "$runtimeType.$name";

  @override
  String toString() => uniqueName;

  /**
   * Return the [ErrorCode] with the given [uniqueName], or `null` if not
   * found.
   */
  static ErrorCode byUniqueName(String uniqueName) {
    if (_uniqueNameToCodeMap == null) {
      _uniqueNameToCodeMap = new HashMap<String, ErrorCode>();
      for (ErrorCode errorCode in values) {
        _uniqueNameToCodeMap[errorCode.uniqueName] = errorCode;
      }
    }
    return _uniqueNameToCodeMap[uniqueName];
  }
}

/**
 * The properties that can be associated with an [AnalysisError].
 */
class ErrorProperty<V> extends Enum<ErrorProperty> {
  /**
   * A property whose value is a list of [FieldElement]s that are final, but
   * not initialized by a constructor.
   */
  static const ErrorProperty<List<FieldElement>> NOT_INITIALIZED_FIELDS =
      const ErrorProperty<List<FieldElement>>('NOT_INITIALIZED_FIELDS', 0);

  /**
   * A property whose value is the name of the library that is used by all
   * of the "part of" directives, so should be used in the "library" directive.
   * Is `null` if there is no a single name used by all of the parts.
   */
  static const ErrorProperty<String> PARTS_LIBRARY_NAME =
      const ErrorProperty<String>('PARTS_LIBRARY_NAME', 1);

  /**
   * A property whose value is a list of [ExecutableElement] that should
   * be but are not implemented by a concrete class.
   */
  static const ErrorProperty<List<ExecutableElement>> UNIMPLEMENTED_METHODS =
      const ErrorProperty<List<ExecutableElement>>('UNIMPLEMENTED_METHODS', 2);

  static const List<ErrorProperty> values = const [
    NOT_INITIALIZED_FIELDS,
    PARTS_LIBRARY_NAME,
    UNIMPLEMENTED_METHODS
  ];

  const ErrorProperty(String name, int ordinal) : super(name, ordinal);
}

/**
 * An object used to create analysis errors and report then to an error
 * listener.
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
   * Initialize a newly created error reporter that will report errors to the
   * given [_errorListener]. Errors will be reported against the
   * [_defaultSource] unless another source is provided later.
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
   * Set the source to be used when reporting errors to the given [source].
   * Setting the source to `null` will cause the default source to be used.
   */
  void set source(Source source) {
    this._source = source ?? _defaultSource;
  }

  /**
   * Creates an error with properties with the given [errorCode] and
   * [arguments]. The [node] is used to compute the location of the error.
   */
  AnalysisErrorWithProperties newErrorWithProperties(
          ErrorCode errorCode, AstNode node, List<Object> arguments) =>
      new AnalysisErrorWithProperties(
          _source, node.offset, node.length, errorCode, arguments);

  /**
   * Report the given [error].
   */
  void reportError(AnalysisError error) {
    _errorListener.onError(error);
  }

  /**
   * Report an error with the given [errorCode] and [arguments]. The [element]
   * is used to compute the location of the error.
   */
  void reportErrorForElement(ErrorCode errorCode, Element element,
      [List<Object> arguments]) {
    int length = 0;
    if (element is ImportElement) {
      length = 6; // 'import'.length
    } else if (element is ExportElement) {
      length = 6; // 'export'.length
    } else {
      length = element.nameLength;
    }
    reportErrorForOffset(errorCode, element.nameOffset, length, arguments);
  }

  /**
   * Report an error with the given [errorCode] and [arguments].
   * The [node] is used to compute the location of the error.
   *
   * If the arguments contain the names of two or more types, the method
   * [reportTypeErrorForNode] should be used and the types
   * themselves (rather than their names) should be passed as arguments.
   */
  void reportErrorForNode(ErrorCode errorCode, AstNode node,
      [List<Object> arguments]) {
    reportErrorForOffset(errorCode, node.offset, node.length, arguments);
  }

  /**
   * Report an error with the given [errorCode] and [arguments]. The location of
   * the error is specified by the given [offset] and [length].
   */
  void reportErrorForOffset(ErrorCode errorCode, int offset, int length,
      [List<Object> arguments]) {
    _errorListener.onError(
        new AnalysisError(_source, offset, length, errorCode, arguments));
  }

  /**
   * Report an error with the given [errorCode] and [arguments]. The location of
   * the error is specified by the given [span].
   */
  void reportErrorForSpan(ErrorCode errorCode, SourceSpan span,
      [List<Object> arguments]) {
    reportErrorForOffset(errorCode, span.start.offset, span.length, arguments);
  }

  /**
   * Report an error with the given [errorCode] and [arguments]. The [token] is
   * used to compute the location of the error.
   */
  void reportErrorForToken(ErrorCode errorCode, Token token,
      [List<Object> arguments]) {
    reportErrorForOffset(errorCode, token.offset, token.length, arguments);
  }

  /**
   * Report an error with the given [errorCode] and [arguments]. The [node] is
   * used to compute the location of the error. The arguments are expected to
   * contain two or more types. Convert the types into strings by using the
   * display names of the types, unless there are two or more types with the
   * same names, in which case the extended display names of the types will be
   * used in order to clarify the message.
   *
   * If there are not two or more types in the argument list, the method
   * [reportErrorForNode] should be used instead.
   */
  void reportTypeErrorForNode(
      ErrorCode errorCode, AstNode node, List<Object> arguments) {
    _convertTypeNames(arguments);
    reportErrorForOffset(errorCode, node.offset, node.length, arguments);
  }

  /**
   * Given an array of [arguments] that is expected to contain two or more
   * types, convert the types into strings by using the display names of the
   * types, unless there are two or more types with the same names, in which
   * case the extended display names of the types will be used in order to
   * clarify the message.
   */
  void _convertTypeNames(List<Object> arguments) {
    String displayName(DartType type) {
      if (type is FunctionType) {
        String name = type.name;
        if (name != null && name.length > 0) {
          StringBuffer buffer = new StringBuffer();
          buffer.write(name);
          (type as TypeImpl).appendTo(buffer);
          return buffer.toString();
        }
      }
      return type.displayName;
    }

    if (_hasEqualTypeNames(arguments)) {
      int count = arguments.length;
      for (int i = 0; i < count; i++) {
        Object argument = arguments[i];
        if (argument is DartType) {
          Element element = argument.element;
          if (element == null) {
            arguments[i] = displayName(argument);
          } else {
            arguments[i] =
                element.getExtendedDisplayName(displayName(argument));
          }
        }
      }
    } else {
      int count = arguments.length;
      for (int i = 0; i < count; i++) {
        Object argument = arguments[i];
        if (argument is DartType) {
          arguments[i] = displayName(argument);
        }
      }
    }
  }

  /**
   * Return `true` if the given array of [arguments] contains two or more types
   * with the same display name.
   */
  bool _hasEqualTypeNames(List<Object> arguments) {
    int count = arguments.length;
    HashSet<String> typeNames = new HashSet<String>();
    for (int i = 0; i < count; i++) {
      Object argument = arguments[i];
      if (argument is DartType && !typeNames.add(argument.displayName)) {
        return true;
      }
    }
    return false;
  }
}

/**
 * The severity of an [ErrorCode].
 */
class ErrorSeverity extends Enum<ErrorSeverity> {
  /**
   * The severity representing a non-error. This is never used for any error
   * code, but is useful for clients.
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
  static const ErrorSeverity WARNING =
      const ErrorSeverity('WARNING', 2, "W", "warning");

  /**
   * The severity representing an error.
   */
  static const ErrorSeverity ERROR =
      const ErrorSeverity('ERROR', 3, "E", "error");

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
   * Parameters:
   * 0: the name of the severity used when producing machine output
   * 1: the name of the severity used when producing readable output
   */
  const ErrorSeverity(
      String name, int ordinal, this.machineCode, this.displayName)
      : super(name, ordinal);

  /**
   * Return the severity constant that represents the greatest severity.
   */
  ErrorSeverity max(ErrorSeverity severity) =>
      this.ordinal >= severity.ordinal ? this : severity;
}

/**
 * The type of an [ErrorCode].
 */
class ErrorType extends Enum<ErrorType> {
  /**
   * Task (todo) comments in user code.
   */
  static const ErrorType TODO = const ErrorType('TODO', 0, ErrorSeverity.INFO);

  /**
   * Extra analysis run over the code to follow best practices, which are not in
   * the Dart Language Specification.
   */
  static const ErrorType HINT = const ErrorType('HINT', 1, ErrorSeverity.INFO);

  /**
   * Compile-time errors are errors that preclude execution. A compile time
   * error must be reported by a Dart compiler before the erroneous code is
   * executed.
   */
  static const ErrorType COMPILE_TIME_ERROR =
      const ErrorType('COMPILE_TIME_ERROR', 2, ErrorSeverity.ERROR);

  /**
   * Checked mode compile-time errors are errors that preclude execution in
   * checked mode.
   */
  static const ErrorType CHECKED_MODE_COMPILE_TIME_ERROR = const ErrorType(
      'CHECKED_MODE_COMPILE_TIME_ERROR', 3, ErrorSeverity.ERROR);

  /**
   * Static warnings are those warnings reported by the static checker. They
   * have no effect on execution. Static warnings must be provided by Dart
   * compilers used during development.
   */
  static const ErrorType STATIC_WARNING =
      const ErrorType('STATIC_WARNING', 4, ErrorSeverity.WARNING);

  /**
   * Many, but not all, static warnings relate to types, in which case they are
   * known as static type warnings.
   */
  static const ErrorType STATIC_TYPE_WARNING =
      const ErrorType('STATIC_TYPE_WARNING', 5, ErrorSeverity.WARNING);

  /**
   * Syntactic errors are errors produced as a result of input that does not
   * conform to the grammar.
   */
  static const ErrorType SYNTACTIC_ERROR =
      const ErrorType('SYNTACTIC_ERROR', 6, ErrorSeverity.ERROR);

  /**
   * Lint warnings describe style and best practice recommendations that can be
   * used to formalize a project's style guidelines.
   */
  static const ErrorType LINT = const ErrorType('LINT', 7, ErrorSeverity.INFO);

  static const List<ErrorType> values = const [
    TODO,
    HINT,
    COMPILE_TIME_ERROR,
    CHECKED_MODE_COMPILE_TIME_ERROR,
    STATIC_WARNING,
    STATIC_TYPE_WARNING,
    SYNTACTIC_ERROR,
    LINT
  ];

  /**
   * The severity of this type of error.
   */
  final ErrorSeverity severity;

  /**
   * Initialize a newly created error type to have the given [name] and
   * [severity].
   */
  const ErrorType(String name, int ordinal, this.severity)
      : super(name, ordinal);

  String get displayName => name.toLowerCase().replaceAll('_', ' ');
}

/**
 * The hints and coding recommendations for best practices which are not
 * mentioned in the Dart Language Specification.
 */
class HintCode extends ErrorCode {
  /**
   * This hint is generated anywhere where the
   * [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE] would have been generated,
   * if we used propagated information for the warnings.
   *
   * Parameters:
   * 0: the name of the actual argument type
   * 1: the name of the expected type
   */
  static const HintCode ARGUMENT_TYPE_NOT_ASSIGNABLE =
      shared_messages.ARGUMENT_TYPE_NOT_ASSIGNABLE_HINT;

  /**
   * When the target expression uses '?.' operator, it can be `null`, so all the
   * subsequent invocations should also use '?.' operator.
   */
  static const HintCode CAN_BE_NULL_AFTER_NULL_AWARE = const HintCode(
      'CAN_BE_NULL_AFTER_NULL_AWARE',
      "The expression uses '?.', so can be 'null'",
      "Replace the '.' with a '?.' in the invocation");

  /**
   * Dead code is code that is never reached, this can happen for instance if a
   * statement follows a return statement.
   */
  static const HintCode DEAD_CODE = const HintCode('DEAD_CODE', "Dead code");

  /**
   * Dead code is code that is never reached. This case covers cases where the
   * user has catch clauses after `catch (e)` or `on Object catch (e)`.
   */
  static const HintCode DEAD_CODE_CATCH_FOLLOWING_CATCH = const HintCode(
      'DEAD_CODE_CATCH_FOLLOWING_CATCH',
      "Dead code, catch clauses after a 'catch (e)' or an 'on Object catch (e)' are never reached");

  /**
   * Dead code is code that is never reached. This case covers cases where the
   * user has an on-catch clause such as `on A catch (e)`, where a supertype of
   * `A` was already caught.
   *
   * Parameters:
   * 0: name of the subtype
   * 1: name of the supertype
   */
  static const HintCode DEAD_CODE_ON_CATCH_SUBTYPE = const HintCode(
      'DEAD_CODE_ON_CATCH_SUBTYPE',
      "Dead code, this on-catch block will never be executed since '{0}' is a subtype of '{1}'");

  /**
   * Deprecated members should not be invoked or used.
   *
   * Parameters:
   * 0: the name of the member
   */
  static const HintCode DEPRECATED_MEMBER_USE =
      const HintCode('DEPRECATED_MEMBER_USE', "'{0}' is deprecated");

  /**
   * Duplicate imports.
   */
  static const HintCode DUPLICATE_IMPORT =
      const HintCode('DUPLICATE_IMPORT', "Duplicate import");

  /**
   * Hint to use the ~/ operator.
   */
  static const HintCode DIVISION_OPTIMIZATION = const HintCode(
      'DIVISION_OPTIMIZATION',
      "The operator x ~/ y is more efficient than (x / y).toInt()");

  /**
   * Hint for the `x is double` type checks.
   */
  static const HintCode IS_DOUBLE = const HintCode('IS_DOUBLE',
      "When compiled to JS, this test might return true when the left hand side is an int");

  /**
   * Hint for the `x is int` type checks.
   */
  static const HintCode IS_INT = const HintCode('IS_INT',
      "When compiled to JS, this test might return true when the left hand side is a double");

  /**
   * Hint for the `x is! double` type checks.
   */
  static const HintCode IS_NOT_DOUBLE = const HintCode('IS_NOT_DOUBLE',
      "When compiled to JS, this test might return false when the left hand side is an int");

  /**
   * Hint for the `x is! int` type checks.
   */
  static const HintCode IS_NOT_INT = const HintCode('IS_NOT_INT',
      "When compiled to JS, this test might return false when the left hand side is a double");

  /**
   * Deferred libraries shouldn't define a top level function 'loadLibrary'.
   */
  static const HintCode IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION = const HintCode(
      'IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION',
      "The library '{0}' defines a top-level function named 'loadLibrary' which is hidden by deferring this library");

  /**
   * This hint is generated anywhere where the
   * [StaticTypeWarningCode.INVALID_ASSIGNMENT] would have been generated, if we
   * used propagated information for the warnings.
   *
   * Parameters:
   * 0: the name of the right hand side type
   * 1: the name of the left hand side type
   */
  static const HintCode INVALID_ASSIGNMENT = const HintCode(
      'INVALID_ASSIGNMENT',
      "A value of type '{0}' cannot be assigned to a variable of type '{1}'");

  /**
   * This hint is generated anywhere a @factory annotation is associated with
   * anything other than a method.
   */
  static const HintCode INVALID_FACTORY_ANNOTATION = const HintCode(
      'INVALID_FACTORY_ANNOTATION',
      "Only methods can be annotated as factories.");

  /**
   * This hint is generated anywhere a @factory annotation is associated with
   * a method that does not declare a return type.
   */
  static const HintCode INVALID_FACTORY_METHOD_DECL = const HintCode(
      'INVALID_FACTORY_METHOD_DECL',
      "Factory method '{0}' must have a return type.");

  /**
   * This hint is generated anywhere a @factory annotation is associated with
   * a non-abstract method that can return anything other than a newly allocated
   * object.
   *
   * Parameters:
   * 0: the name of the method
   */
  static const HintCode INVALID_FACTORY_METHOD_IMPL = const HintCode(
      'INVALID_FACTORY_METHOD_IMPL',
      "Factory method '{0}' does not return a newly allocated object.");

  /**
   * This hint is generated anywhere where a member annotated with `@protected`
   * is used outside an instance member of a subclass.
   *
   * Parameters:
   * 0: the name of the member
   * 1: the name of the defining class
   */
  static const HintCode INVALID_USE_OF_PROTECTED_MEMBER = const HintCode(
      'INVALID_USE_OF_PROTECTED_MEMBER',
      "The member '{0}' can only be used within instance members of subclasses of '{1}'");

  /**
   * Generate a hint for a constructor, function or method invocation where a
   * required parameter is missing.
   *
   * Parameters:
   * 0: the name of the parameter
   */
  static const HintCode MISSING_REQUIRED_PARAM = const HintCode(
      'MISSING_REQUIRED_PARAM', "The parameter '{0}' is required.");

  /**
   * Generate a hint for a constructor, function or method invocation where a
   * required parameter is missing.
   *
   * Parameters:
   * 0: the name of the parameter
   * 1: message details
   */
  static const HintCode MISSING_REQUIRED_PARAM_WITH_DETAILS = const HintCode(
      'MISSING_REQUIRED_PARAM_WITH_DETAILS',
      "The parameter '{0}' is required. {1}");

  /**
   * Generate a hint for an element that is annotated with `@JS(...)` whose
   * library declaration is not similarly annotated.
   */
  static const HintCode MISSING_JS_LIB_ANNOTATION = const HintCode(
      'MISSING_JS_LIB_ANNOTATION',
      "The @JS() annotation can only be used if it is also declared on the library directive.");

  /**
   * Generate a hint for methods or functions that have a return type, but do
   * not have a non-void return statement on all branches. At the end of methods
   * or functions with no return, Dart implicitly returns `null`, avoiding these
   * implicit returns is considered a best practice.
   *
   * Parameters:
   * 0: the name of the declared return type
   */
  static const HintCode MISSING_RETURN = const HintCode(
      'MISSING_RETURN',
      "This function declares a return type of '{0}', but does not end with a return statement",
      "Either add a return statement or change the return type to 'void'");

  /**
   * Generate a hint for methods that override methods annotated `@mustCallSuper`
   * that do not invoke the overridden super method.
   *
   * Parameters:
   * 0: the name of the class declaring the overriden method
   */
  static const HintCode MUST_CALL_SUPER = const HintCode(
      'MUST_CALL_SUPER',
      "This method overrides a method annotated as @mustCall super in '{0}', "
      "but does invoke the overriden method");

  /**
   * A condition in a control flow statement could evaluate to `null` because it
   * uses the null-aware '?.' operator.
   */
  static const HintCode NULL_AWARE_IN_CONDITION = const HintCode(
      'NULL_AWARE_IN_CONDITION',
      "The value of the '?.' operator can be 'null', which is not appropriate in a condition",
      "Replace the '?.' with a '.', testing the left-hand side for null if necessary");

  /**
   * A getter with the override annotation does not override an existing getter.
   */
  static const HintCode OVERRIDE_ON_NON_OVERRIDING_GETTER = const HintCode(
      'OVERRIDE_ON_NON_OVERRIDING_GETTER',
      "Getter does not override an inherited getter");

  /**
   * A field with the override annotation does not override a getter or setter.
   */
  static const HintCode OVERRIDE_ON_NON_OVERRIDING_FIELD = const HintCode(
      'OVERRIDE_ON_NON_OVERRIDING_FIELD',
      "Field does not override an inherited getter or setter");

  /**
   * A method with the override annotation does not override an existing method.
   */
  static const HintCode OVERRIDE_ON_NON_OVERRIDING_METHOD = const HintCode(
      'OVERRIDE_ON_NON_OVERRIDING_METHOD',
      "Method does not override an inherited method");

  /**
   * A setter with the override annotation does not override an existing setter.
   */
  static const HintCode OVERRIDE_ON_NON_OVERRIDING_SETTER = const HintCode(
      'OVERRIDE_ON_NON_OVERRIDING_SETTER',
      "Setter does not override an inherited setter");

  /**
   * Hint for classes that override equals, but not hashCode.
   *
   * Parameters:
   * 0: the name of the current class
   */
  static const HintCode OVERRIDE_EQUALS_BUT_NOT_HASH_CODE = const HintCode(
      'OVERRIDE_EQUALS_BUT_NOT_HASH_CODE',
      "The class '{0}' overrides 'operator==', but not 'get hashCode'");

  /**
   * Type checks of the type `x is! Null` should be done with `x != null`.
   */
  static const HintCode TYPE_CHECK_IS_NOT_NULL = const HintCode(
      'TYPE_CHECK_IS_NOT_NULL',
      "Tests for non-null should be done with '!= null'");

  /**
   * Type checks of the type `x is Null` should be done with `x == null`.
   */
  static const HintCode TYPE_CHECK_IS_NULL = const HintCode(
      'TYPE_CHECK_IS_NULL', "Tests for null should be done with '== null'");

  /**
   * This hint is generated anywhere where the
   * [StaticTypeWarningCode.UNDEFINED_GETTER] or
   * [StaticWarningCode.UNDEFINED_GETTER] would have been generated, if we used
   * propagated information for the warnings.
   *
   * Parameters:
   * 0: the name of the getter
   * 1: the name of the enclosing type where the getter is being looked for
   */
  static const HintCode UNDEFINED_GETTER =
      shared_messages.UNDEFINED_GETTER_HINT;

  /**
   * An undefined name hidden in an import or export directive.
   */
  static const HintCode UNDEFINED_HIDDEN_NAME = const HintCode(
      'UNDEFINED_HIDDEN_NAME',
      "The library '{0}' doesn't export a member with the hidden name '{1}'");

  /**
   * This hint is generated anywhere where the
   * [StaticTypeWarningCode.UNDEFINED_METHOD] would have been generated, if we
   * used propagated information for the warnings.
   *
   * Parameters:
   * 0: the name of the method that is undefined
   * 1: the resolved type name that the method lookup is happening on
   */
  static const HintCode UNDEFINED_METHOD =
      shared_messages.UNDEFINED_METHOD_HINT;

  /**
   * This hint is generated anywhere where the
   * [StaticTypeWarningCode.UNDEFINED_OPERATOR] would have been generated, if we
   * used propagated information for the warnings.
   *
   * Parameters:
   * 0: the name of the operator
   * 1: the name of the enclosing type where the operator is being looked for
   */
  static const HintCode UNDEFINED_OPERATOR =
      shared_messages.UNDEFINED_OPERATOR_HINT;

  /**
   * This hint is generated anywhere where the
   * [StaticTypeWarningCode.UNDEFINED_SETTER] or
   * [StaticWarningCode.UNDEFINED_SETTER] would have been generated, if we used
   * propagated information for the warnings.
   *
   * Parameters:
   * 0: the name of the setter
   * 1: the name of the enclosing type where the setter is being looked for
   */
  static const HintCode UNDEFINED_SETTER =
      shared_messages.UNDEFINED_SETTER_HINT;

  /**
   * An undefined name shown in an import or export directive.
   */
  static const HintCode UNDEFINED_SHOWN_NAME = const HintCode(
      'UNDEFINED_SHOWN_NAME',
      "The library '{0}' doesn't export a member with the shown name '{1}'");

  /**
   * Unnecessary cast.
   */
  static const HintCode UNNECESSARY_CAST =
      const HintCode('UNNECESSARY_CAST', "Unnecessary cast");

  /**
   * Unnecessary `noSuchMethod` declaration.
   */
  static const HintCode UNNECESSARY_NO_SUCH_METHOD = const HintCode(
      'UNNECESSARY_NO_SUCH_METHOD', "Unnecessary 'noSuchMethod' declaration");

  /**
   * Unnecessary type checks, the result is always true.
   */
  static const HintCode UNNECESSARY_TYPE_CHECK_FALSE = const HintCode(
      'UNNECESSARY_TYPE_CHECK_FALSE',
      "Unnecessary type check, the result is always false");

  /**
   * Unnecessary type checks, the result is always false.
   */
  static const HintCode UNNECESSARY_TYPE_CHECK_TRUE = const HintCode(
      'UNNECESSARY_TYPE_CHECK_TRUE',
      "Unnecessary type check, the result is always true");

  /**
   * See [Modifier.IS_USED_IN_LIBRARY].
   */
  static const HintCode UNUSED_ELEMENT =
      const HintCode('UNUSED_ELEMENT', "The {0} '{1}' is not used");

  /**
   * Unused fields are fields which are never read.
   */
  static const HintCode UNUSED_FIELD = const HintCode(
      'UNUSED_FIELD', "The value of the field '{0}' is not used");

  /**
   * Unused imports are imports which are never used.
   */
  static const HintCode UNUSED_IMPORT =
      const HintCode('UNUSED_IMPORT', "Unused import");

  /**
   * Unused catch exception variables.
   */
  static const HintCode UNUSED_CATCH_CLAUSE = const HintCode(
      'UNUSED_CATCH_CLAUSE',
      "The exception variable '{0}' is not used, so the 'catch' clause can be removed");

  /**
   * Unused catch stack trace variables.
   */
  static const HintCode UNUSED_CATCH_STACK = const HintCode(
      'UNUSED_CATCH_STACK',
      "The stack trace variable '{0}' is not used and can be removed");

  /**
   * Unused local variables are local variables which are never read.
   */
  static const HintCode UNUSED_LOCAL_VARIABLE = const HintCode(
      'UNUSED_LOCAL_VARIABLE',
      "The value of the local variable '{0}' is not used");

  /**
   * Unused shown names are names shown on imports which are never used.
   */
  static const HintCode UNUSED_SHOWN_NAME = const HintCode(
      'UNUSED_SHOWN_NAME', "The name {0} is shown, but not used.");

  /**
   * Hint for cases where the source expects a method or function to return a
   * non-void result, but the method or function signature returns void.
   *
   * Parameters:
   * 0: the name of the method or function that returns void
   */
  static const HintCode USE_OF_VOID_RESULT = const HintCode(
      'USE_OF_VOID_RESULT',
      "The result of '{0}' is being used, even though it is declared to be 'void'");

  /**
   * It is a bad practice for a source file in a package "lib" directory
   * hierarchy to traverse outside that directory hierarchy. For example, a
   * source file in the "lib" directory should not contain a directive such as
   * `import '../web/some.dart'` which references a file outside the lib
   * directory.
   */
  static const HintCode FILE_IMPORT_INSIDE_LIB_REFERENCES_FILE_OUTSIDE =
      const HintCode('FILE_IMPORT_INSIDE_LIB_REFERENCES_FILE_OUTSIDE',
          "A file in the 'lib' directory hierarchy should not reference a file outside that hierarchy");

  /**
   * It is a bad practice for a source file ouside a package "lib" directory
   * hierarchy to traverse into that directory hierarchy. For example, a source
   * file in the "web" directory should not contain a directive such as
   * `import '../lib/some.dart'` which references a file inside the lib
   * directory.
   */
  static const HintCode FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE =
      const HintCode('FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE',
          "A file outside the 'lib' directory hierarchy should not reference a file inside that hierarchy. Use a package: reference instead.");

  /**
   * It is a bad practice for a package import to reference anything outside the
   * given package, or more generally, it is bad practice for a package import
   * to contain a "..". For example, a source file should not contain a
   * directive such as `import 'package:foo/../some.dart'`.
   */
  static const HintCode PACKAGE_IMPORT_CONTAINS_DOT_DOT = const HintCode(
      'PACKAGE_IMPORT_CONTAINS_DOT_DOT',
      "A package import should not contain '..'");

  /**
   * Initialize a newly created error code to have the given [name]. The message
   * associated with the error will be created from the given [message]
   * template. The correction associated with the error will be created from the
   * given [correction] template.
   */
  const HintCode(String name, String message, [String correction])
      : super(name, message, correction);

  @override
  ErrorSeverity get errorSeverity => ErrorType.HINT.severity;

  @override
  ErrorType get type => ErrorType.HINT;
}

/**
 * The error codes used for errors in HTML files. The convention for this
 * class is for the name of the error code to indicate the problem that caused
 * the error to be generated and for the error message to explain what is wrong
 * and, when appropriate, how the problem can be corrected.
 */
class HtmlErrorCode extends ErrorCode {
  /**
   * An error code indicating that there is a syntactic error in the file.
   *
   * Parameters:
   * 0: the error message from the parse error
   */
  static const HtmlErrorCode PARSE_ERROR =
      const HtmlErrorCode('PARSE_ERROR', '{0}');

  /**
   * Initialize a newly created error code to have the given [name]. The message
   * associated with the error will be created from the given [message]
   * template. The correction associated with the error will be created from the
   * given [correction] template.
   */
  const HtmlErrorCode(String name, String message, [String correction])
      : super(name, message, correction);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType.COMPILE_TIME_ERROR;
}

/**
 * The error codes used for warnings in HTML files. The convention for this
 * class is for the name of the error code to indicate the problem that caused
 * the error to be generated and for the error message to explain what is wrong
 * and, when appropriate, how the problem can be corrected.
 */
class HtmlWarningCode extends ErrorCode {
  /**
   * An error code indicating that the value of the 'src' attribute of a Dart
   * script tag is not a valid URI.
   *
   * Parameters:
   * 0: the URI that is invalid
   */
  static const HtmlWarningCode INVALID_URI =
      const HtmlWarningCode('INVALID_URI', "Invalid URI syntax: '{0}'");

  /**
   * An error code indicating that the value of the 'src' attribute of a Dart
   * script tag references a file that does not exist.
   *
   * Parameters:
   * 0: the URI pointing to a non-existent file
   */
  static const HtmlWarningCode URI_DOES_NOT_EXIST = const HtmlWarningCode(
      'URI_DOES_NOT_EXIST', "Target of URI does not exist: '{0}'");

  /**
   * Initialize a newly created error code to have the given [name]. The message
   * associated with the error will be created from the given [message]
   * template. The correction associated with the error will be created from the
   * given [correction] template.
   */
  const HtmlWarningCode(String name, String message, [String correction])
      : super(name, message, correction);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.WARNING;

  @override
  ErrorType get type => ErrorType.STATIC_WARNING;
}

/**
 * Defines style and best practice recommendations.
 *
 * Unlike [HintCode]s, which are akin to traditional static warnings from a
 * compiler, lint recommendations focus on matters of style and practices that
 * might aggregated to define a project's style guide.
 */
class LintCode extends ErrorCode {
  const LintCode(String name, String message, [String correction])
      : super(name, message, correction);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.INFO;

  @override
  ErrorType get type => ErrorType.LINT;
}

/**
 * The error codes used for static type warnings. The convention for this class
 * is for the name of the error code to indicate the problem that caused the
 * error to be generated and for the error message to explain what is wrong and,
 * when appropriate, how the problem can be corrected.
 */
class StaticTypeWarningCode extends ErrorCode {
  /**
   * 12.7 Lists: A fresh instance (7.6.1) <i>a</i>, of size <i>n</i>, whose
   * class implements the built-in class <i>List&lt;E></i> is allocated.
   *
   * Parameters:
   * 0: the number of provided type arguments
   */
  static const StaticTypeWarningCode EXPECTED_ONE_LIST_TYPE_ARGUMENTS =
      const StaticTypeWarningCode('EXPECTED_ONE_LIST_TYPE_ARGUMENTS',
          "List literal requires exactly one type arguments or none, but {0} found");

  /**
   * 12.8 Maps: A fresh instance (7.6.1) <i>m</i>, of size <i>n</i>, whose class
   * implements the built-in class <i>Map&lt;K, V></i> is allocated.
   *
   * Parameters:
   * 0: the number of provided type arguments
   */
  static const StaticTypeWarningCode EXPECTED_TWO_MAP_TYPE_ARGUMENTS =
      const StaticTypeWarningCode('EXPECTED_TWO_MAP_TYPE_ARGUMENTS',
          "Map literal requires exactly two type arguments or none, but {0} found");

  /**
   * 9 Functions: It is a static warning if the declared return type of a
   * function marked async* may not be assigned to Stream.
   */
  static const StaticTypeWarningCode ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE =
      const StaticTypeWarningCode('ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE',
          "Functions marked 'async*' must have a return type assignable to 'Stream'");

  /**
   * 9 Functions: It is a static warning if the declared return type of a
   * function marked async may not be assigned to Future.
   */
  static const StaticTypeWarningCode ILLEGAL_ASYNC_RETURN_TYPE =
      const StaticTypeWarningCode('ILLEGAL_ASYNC_RETURN_TYPE',
          "Functions marked 'async' must have a return type assignable to 'Future'");

  /**
   * 9 Functions: It is a static warning if the declared return type of a
   * function marked sync* may not be assigned to Iterable.
   */
  static const StaticTypeWarningCode ILLEGAL_SYNC_GENERATOR_RETURN_TYPE =
      const StaticTypeWarningCode('ILLEGAL_SYNC_GENERATOR_RETURN_TYPE',
          "Functions marked 'sync*' must have a return type assignable to 'Iterable'");

  /**
   * 12.18 Assignment: Let <i>T</i> be the static type of <i>e<sub>1</sub></i>.
   * It is a static type warning if <i>T</i> does not have an accessible
   * instance setter named <i>v=</i>.
   *
   * See [UNDEFINED_SETTER].
   */
  static const StaticTypeWarningCode INACCESSIBLE_SETTER =
      const StaticTypeWarningCode('INACCESSIBLE_SETTER', "");

  /**
   * 8.1.1 Inheritance and Overriding: However, if the above rules would cause
   * multiple members <i>m<sub>1</sub>, &hellip;, m<sub>k</sub></i> with the
   * same name <i>n</i> that would be inherited (because identically named
   * members existed in several superinterfaces) then at most one member is
   * inherited.
   *
   * If the static types <i>T<sub>1</sub>, &hellip;, T<sub>k</sub></i> of the
   * members <i>m<sub>1</sub>, &hellip;, m<sub>k</sub></i> are not identical,
   * then there must be a member <i>m<sub>x</sub></i> such that <i>T<sub>x</sub>
   * &lt;: T<sub>i</sub>, 1 &lt;= x &lt;= k</i> for all <i>i, 1 &lt;= i &lt;=
   * k</i>, or a static type warning occurs. The member that is inherited is
   * <i>m<sub>x</sub></i>, if it exists; otherwise:
   * * Let <i>numberOfPositionals</i>(<i>f</i>) denote the number of positional
   *   parameters of a function <i>f</i>, and let
   *   <i>numberOfRequiredParams</i>(<i>f</i>) denote the number of required
   *   parameters of a function <i>f</i>. Furthermore, let <i>s</i> denote the
   *   set of all named parameters of the <i>m<sub>1</sub>, &hellip;,
   *   m<sub>k</sub></i>. Then let
   * * <i>h = max(numberOfPositionals(m<sub>i</sub>)),</i>
   * * <i>r = min(numberOfRequiredParams(m<sub>i</sub>)), for all <i>i</i>, 1 <=
   *   i <= k.</i> If <i>r <= h</i> then <i>I</i> has a method named <i>n</i>,
   *   with <i>r</i> required parameters of type <b>dynamic</b>, <i>h</i>
   *   positional parameters of type <b>dynamic</b>, named parameters <i>s</i>
   *   of type <b>dynamic</b> and return type <b>dynamic</b>.
   * * Otherwise none of the members <i>m<sub>1</sub>, &hellip;,
   *   m<sub>k</sub></i> is inherited.
   */
  static const StaticTypeWarningCode INCONSISTENT_METHOD_INHERITANCE =
      const StaticTypeWarningCode('INCONSISTENT_METHOD_INHERITANCE',
          "'{0}' is inherited by at least two interfaces inconsistently, from {1}");

  /**
   * 12.15.1 Ordinary Invocation: It is a static type warning if <i>T</i> does
   * not have an accessible (3.2) instance member named <i>m</i>.
   *
   * Parameters:
   * 0: the name of the static member
   *
   * See [UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER].
   */
  static const StaticTypeWarningCode INSTANCE_ACCESS_TO_STATIC_MEMBER =
      const StaticTypeWarningCode('INSTANCE_ACCESS_TO_STATIC_MEMBER',
          "Static member '{0}' cannot be accessed using instance access");

  /**
   * 12.18 Assignment: It is a static type warning if the static type of
   * <i>e</i> may not be assigned to the static type of <i>v</i>. The static
   * type of the expression <i>v = e</i> is the static type of <i>e</i>.
   *
   * 12.18 Assignment: It is a static type warning if the static type of
   * <i>e</i> may not be assigned to the static type of <i>C.v</i>. The static
   * type of the expression <i>C.v = e</i> is the static type of <i>e</i>.
   *
   * 12.18 Assignment: Let <i>T</i> be the static type of <i>e<sub>1</sub></i>.
   * It is a static type warning if the static type of <i>e<sub>2</sub></i> may
   * not be assigned to <i>T</i>.
   *
   * Parameters:
   * 0: the name of the right hand side type
   * 1: the name of the left hand side type
   */
  static const StaticTypeWarningCode INVALID_ASSIGNMENT =
      const StaticTypeWarningCode('INVALID_ASSIGNMENT',
          "A value of type '{0}' cannot be assigned to a variable of type '{1}'");

  /**
   * 12.15.1 Ordinary Invocation: An ordinary method invocation <i>i</i> has the
   * form <i>o.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>:
   * a<sub>n+1</sub>, &hellip; x<sub>n+k</sub>: a<sub>n+k</sub>)</i>.
   *
   * Let <i>T</i> be the static type of <i>o</i>. It is a static type warning if
   * <i>T</i> does not have an accessible instance member named <i>m</i>. If
   * <i>T.m</i> exists, it is a static warning if the type <i>F</i> of
   * <i>T.m</i> may not be assigned to a function type. If <i>T.m</i> does not
   * exist, or if <i>F</i> is not a function type, the static type of <i>i</i>
   * is dynamic.
   *
   * 12.15.3 Static Invocation: It is a static type warning if the type <i>F</i>
   * of <i>C.m</i> may not be assigned to a function type.
   *
   * 12.15.4 Super Invocation: A super method invocation <i>i</i> has the form
   * <i>super.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>:
   * a<sub>n+1</sub>, &hellip; x<sub>n+k</sub>: a<sub>n+k</sub>)</i>. If
   * <i>S.m</i> exists, it is a static warning if the type <i>F</i> of
   * <i>S.m</i> may not be assigned to a function type.
   *
   * Parameters:
   * 0: the name of the identifier that is not a function type
   */
  static const StaticTypeWarningCode INVOCATION_OF_NON_FUNCTION =
      const StaticTypeWarningCode(
          'INVOCATION_OF_NON_FUNCTION', "'{0}' is not a method");

  /**
   * 12.14.4 Function Expression Invocation: A function expression invocation
   * <i>i</i> has the form <i>e<sub>f</sub>(a<sub>1</sub>, &hellip;,
   * a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;, x<sub>n+k</sub>:
   * a<sub>n+k</sub>)</i>, where <i>e<sub>f</sub></i> is an expression.
   *
   * It is a static type warning if the static type <i>F</i> of
   * <i>e<sub>f</sub></i> may not be assigned to a function type.
   */
  static const StaticTypeWarningCode INVOCATION_OF_NON_FUNCTION_EXPRESSION =
      const StaticTypeWarningCode('INVOCATION_OF_NON_FUNCTION_EXPRESSION',
          "Cannot invoke a non-function");

  /**
   * 12.20 Conditional: It is a static type warning if the type of
   * <i>e<sub>1</sub></i> may not be assigned to bool.
   *
   * 13.5 If: It is a static type warning if the type of the expression <i>b</i>
   * may not be assigned to bool.
   *
   * 13.7 While: It is a static type warning if the type of <i>e</i> may not be
   * assigned to bool.
   *
   * 13.8 Do: It is a static type warning if the type of <i>e</i> cannot be
   * assigned to bool.
   */
  static const StaticTypeWarningCode NON_BOOL_CONDITION =
      const StaticTypeWarningCode(
          'NON_BOOL_CONDITION', "Conditions must have a static type of 'bool'");

  /**
   * 13.15 Assert: It is a static type warning if the type of <i>e</i> may not
   * be assigned to either bool or () &rarr; bool
   */
  static const StaticTypeWarningCode NON_BOOL_EXPRESSION =
      const StaticTypeWarningCode('NON_BOOL_EXPRESSION',
          "Assertions must be on either a 'bool' or '() -> bool'");

  /**
   * 12.28 Unary Expressions: The expression !<i>e</i> is equivalent to the
   * expression <i>e</i>?<b>false<b> : <b>true</b>.
   *
   * 12.20 Conditional: It is a static type warning if the type of
   * <i>e<sub>1</sub></i> may not be assigned to bool.
   */
  static const StaticTypeWarningCode NON_BOOL_NEGATION_EXPRESSION =
      const StaticTypeWarningCode('NON_BOOL_NEGATION_EXPRESSION',
          "Negation argument must have a static type of 'bool'");

  /**
   * 12.21 Logical Boolean Expressions: It is a static type warning if the
   * static types of both of <i>e<sub>1</sub></i> and <i>e<sub>2</sub></i> may
   * not be assigned to bool.
   *
   * Parameters:
   * 0: the lexeme of the logical operator
   */
  static const StaticTypeWarningCode NON_BOOL_OPERAND =
      const StaticTypeWarningCode('NON_BOOL_OPERAND',
          "The operands of the '{0}' operator must be assignable to 'bool'");

  /**
   *
   */
  static const StaticTypeWarningCode NON_NULLABLE_FIELD_NOT_INITIALIZED =
      const StaticTypeWarningCode('NON_NULLABLE_FIELD_NOT_INITIALIZED',
          "Variable '{0}' of non-nullable type '{1}' must be initialized");

  /**
   * 15.8 Parameterized Types: It is a static type warning if <i>A<sub>i</sub>,
   * 1 &lt;= i &lt;= n</i> does not denote a type in the enclosing lexical scope.
   */
  static const StaticTypeWarningCode NON_TYPE_AS_TYPE_ARGUMENT =
      const StaticTypeWarningCode('NON_TYPE_AS_TYPE_ARGUMENT',
          "The name '{0}' is not a type and cannot be used as a parameterized type");

  /**
   * 13.11 Return: It is a static type warning if the type of <i>e</i> may not
   * be assigned to the declared return type of the immediately enclosing
   * function.
   *
   * Parameters:
   * 0: the return type as declared in the return statement
   * 1: the expected return type as defined by the method
   * 2: the name of the method
   */
  static const StaticTypeWarningCode RETURN_OF_INVALID_TYPE =
      shared_messages.RETURN_OF_INVALID_TYPE;

  /**
   * 12.11 Instance Creation: It is a static type warning if any of the type
   * arguments to a constructor of a generic type <i>G</i> invoked by a new
   * expression or a constant object expression are not subtypes of the bounds
   * of the corresponding formal type parameters of <i>G</i>.
   *
   * 15.8 Parameterized Types: If <i>S</i> is the static type of a member
   * <i>m</i> of <i>G</i>, then the static type of the member <i>m</i> of
   * <i>G&lt;A<sub>1</sub>, &hellip;, A<sub>n</sub>&gt;</i> is <i>[A<sub>1</sub>,
   * &hellip;, A<sub>n</sub>/T<sub>1</sub>, &hellip;, T<sub>n</sub>]S</i> where
   * <i>T<sub>1</sub>, &hellip;, T<sub>n</sub></i> are the formal type
   * parameters of <i>G</i>. Let <i>B<sub>i</sub></i> be the bounds of
   * <i>T<sub>i</sub>, 1 &lt;= i &lt;= n</i>. It is a static type warning if
   * <i>A<sub>i</sub></i> is not a subtype of <i>[A<sub>1</sub>, &hellip;,
   * A<sub>n</sub>/T<sub>1</sub>, &hellip;, T<sub>n</sub>]B<sub>i</sub>, 1 &lt;=
   * i &lt;= n</i>.
   *
   * 7.6.2 Factories: It is a static type warning if any of the type arguments
   * to <i>k'</i> are not subtypes of the bounds of the corresponding formal
   * type parameters of type.
   *
   * Parameters:
   * 0: the name of the type used in the instance creation that should be
   *    limited by the bound as specified in the class declaration
   * 1: the name of the bounding type
   *
   * See [TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND].
   */
  static const StaticTypeWarningCode TYPE_ARGUMENT_NOT_MATCHING_BOUNDS =
      const StaticTypeWarningCode(
          'TYPE_ARGUMENT_NOT_MATCHING_BOUNDS', "'{0}' does not extend '{1}'");

  /**
   * 10 Generics: It is a static type warning if a type parameter is a supertype
   * of its upper bound.
   *
   * Parameters:
   * 0: the name of the type parameter
   *
   * See [TYPE_ARGUMENT_NOT_MATCHING_BOUNDS].
   */
  static const StaticTypeWarningCode TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND =
      const StaticTypeWarningCode('TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND',
          "'{0}' cannot be a supertype of its upper bound");

  /**
   * 12.17 Getter Invocation: It is a static warning if there is no class
   * <i>C</i> in the enclosing lexical scope of <i>i</i>, or if <i>C</i> does
   * not declare, implicitly or explicitly, a getter named <i>m</i>.
   *
   * Parameters:
   * 0: the name of the enumeration constant that is not defined
   * 1: the name of the enumeration used to access the constant
   */
  static const StaticTypeWarningCode UNDEFINED_ENUM_CONSTANT =
      shared_messages.UNDEFINED_ENUM_CONSTANT;

  /**
   * 12.15.3 Unqualified Invocation: If there exists a lexically visible
   * declaration named <i>id</i>, let <i>f<sub>id</sub></i> be the innermost
   * such declaration. Then: [skip]. Otherwise, <i>f<sub>id</sub></i> is
   * considered equivalent to the ordinary method invocation
   * <b>this</b>.<i>id</i>(<i>a<sub>1</sub></i>, ..., <i>a<sub>n</sub></i>,
   * <i>x<sub>n+1</sub></i> : <i>a<sub>n+1</sub></i>, ...,
   * <i>x<sub>n+k</sub></i> : <i>a<sub>n+k</sub></i>).
   *
   * Parameters:
   * 0: the name of the method that is undefined
   */
  static const StaticTypeWarningCode UNDEFINED_FUNCTION =
      shared_messages.UNDEFINED_FUNCTION;

  /**
   * 12.17 Getter Invocation: Let <i>T</i> be the static type of <i>e</i>. It is
   * a static type warning if <i>T</i> does not have a getter named <i>m</i>.
   *
   * Parameters:
   * 0: the name of the getter
   * 1: the name of the enclosing type where the getter is being looked for
   */
  static const StaticTypeWarningCode UNDEFINED_GETTER =
      shared_messages.UNDEFINED_GETTER_STATIC_TYPE_WARNING;

  /**
   * 12.15.1 Ordinary Invocation: Let <i>T</i> be the static type of <i>o</i>.
   * It is a static type warning if <i>T</i> does not have an accessible
   * instance member named <i>m</i>.
   *
   * Parameters:
   * 0: the name of the method that is undefined
   * 1: the resolved type name that the method lookup is happening on
   */
  static const StaticTypeWarningCode UNDEFINED_METHOD =
      shared_messages.UNDEFINED_METHOD_STATIC_TYPE_WARNING;

  /**
   * 12.15.1 Ordinary Invocation: Let <i>T</i> be the static type of <i>o</i>.
   * It is a static type warning if <i>T</i> does not have an accessible
   * instance member named <i>m</i>.
   *
   * Parameters:
   * 0: the name of the method that is undefined
   * 1: the resolved type name that the method lookup is happening on
   */
  static const StaticTypeWarningCode UNDEFINED_METHOD_WITH_CONSTRUCTOR =
      shared_messages.UNDEFINED_METHOD_WITH_CONSTRUCTOR;

  /**
   * 12.18 Assignment: Evaluation of an assignment of the form
   * <i>e<sub>1</sub></i>[<i>e<sub>2</sub></i>] = <i>e<sub>3</sub></i> is
   * equivalent to the evaluation of the expression (a, i, e){a.[]=(i, e);
   * return e;} (<i>e<sub>1</sub></i>, <i>e<sub>2</sub></i>,
   * <i>e<sub>2</sub></i>).
   *
   * 12.29 Assignable Expressions: An assignable expression of the form
   * <i>e<sub>1</sub></i>[<i>e<sub>2</sub></i>] is evaluated as a method
   * invocation of the operator method [] on <i>e<sub>1</sub></i> with argument
   * <i>e<sub>2</sub></i>.
   *
   * 12.15.1 Ordinary Invocation: Let <i>T</i> be the static type of <i>o</i>.
   * It is a static type warning if <i>T</i> does not have an accessible
   * instance member named <i>m</i>.
   *
   * Parameters:
   * 0: the name of the operator
   * 1: the name of the enclosing type where the operator is being looked for
   */
  static const StaticTypeWarningCode UNDEFINED_OPERATOR =
      shared_messages.UNDEFINED_OPERATOR_STATIC_TYPE_WARNING;

  /**
   * 12.18 Assignment: Let <i>T</i> be the static type of <i>e<sub>1</sub></i>.
   * It is a static type warning if <i>T</i> does not have an accessible
   * instance setter named <i>v=</i>.
   *
   * Parameters:
   * 0: the name of the setter
   * 1: the name of the enclosing type where the setter is being looked for
   *
   * See [INACCESSIBLE_SETTER].
   */
  static const StaticTypeWarningCode UNDEFINED_SETTER =
      shared_messages.UNDEFINED_SETTER_STATIC_TYPE_WARNING;

  /**
   * 12.17 Getter Invocation: Let <i>T</i> be the static type of <i>e</i>. It is
   * a static type warning if <i>T</i> does not have a getter named <i>m</i>.
   *
   * Parameters:
   * 0: the name of the getter
   * 1: the name of the enclosing type where the getter is being looked for
   */
  static const StaticTypeWarningCode UNDEFINED_SUPER_GETTER =
      shared_messages.UNDEFINED_SUPER_GETTER_STATIC_TYPE_WARNING;

  /**
   * 12.15.4 Super Invocation: A super method invocation <i>i</i> has the form
   * <i>super.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>:
   * a<sub>n+1</sub>, &hellip; x<sub>n+k</sub>: a<sub>n+k</sub>)</i>. It is a
   * static type warning if <i>S</i> does not have an accessible instance member
   * named <i>m</i>.
   *
   * Parameters:
   * 0: the name of the method that is undefined
   * 1: the resolved type name that the method lookup is happening on
   */
  static const StaticTypeWarningCode UNDEFINED_SUPER_METHOD =
      shared_messages.UNDEFINED_SUPER_METHOD;

  /**
   * 12.18 Assignment: Evaluation of an assignment of the form
   * <i>e<sub>1</sub></i>[<i>e<sub>2</sub></i>] = <i>e<sub>3</sub></i> is
   * equivalent to the evaluation of the expression (a, i, e){a.[]=(i, e);
   * return e;} (<i>e<sub>1</sub></i>, <i>e<sub>2</sub></i>,
   * <i>e<sub>2</sub></i>).
   *
   * 12.29 Assignable Expressions: An assignable expression of the form
   * <i>e<sub>1</sub></i>[<i>e<sub>2</sub></i>] is evaluated as a method
   * invocation of the operator method [] on <i>e<sub>1</sub></i> with argument
   * <i>e<sub>2</sub></i>.
   *
   * 12.15.1 Ordinary Invocation: Let <i>T</i> be the static type of <i>o</i>.
   * It is a static type warning if <i>T</i> does not have an accessible
   * instance member named <i>m</i>.
   *
   * Parameters:
   * 0: the name of the operator
   * 1: the name of the enclosing type where the operator is being looked for
   */
  static const StaticTypeWarningCode UNDEFINED_SUPER_OPERATOR =
      shared_messages.UNDEFINED_SUPER_OPERATOR;

  /**
   * 12.18 Assignment: Let <i>T</i> be the static type of <i>e<sub>1</sub></i>.
   * It is a static type warning if <i>T</i> does not have an accessible
   * instance setter named <i>v=</i>.
   *
   * Parameters:
   * 0: the name of the setter
   * 1: the name of the enclosing type where the setter is being looked for
   *
   * See [INACCESSIBLE_SETTER].
   */
  static const StaticTypeWarningCode UNDEFINED_SUPER_SETTER =
      shared_messages.UNDEFINED_SUPER_SETTER_STATIC_TYPE_WARNING;

  /**
   * 12.15.1 Ordinary Invocation: It is a static type warning if <i>T</i> does
   * not have an accessible (3.2) instance member named <i>m</i>.
   *
   * This is a specialization of [INSTANCE_ACCESS_TO_STATIC_MEMBER] that is used
   * when we are able to find the name defined in a supertype. It exists to
   * provide a more informative error message.
   */
  static const StaticTypeWarningCode
      UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER =
      const StaticTypeWarningCode(
          'UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER',
          "Static members from supertypes must be qualified by the name of the defining type");

  /**
   * 15.8 Parameterized Types: It is a static type warning if <i>G</i> is not a
   * generic type with exactly <i>n</i> type parameters.
   *
   * Parameters:
   * 0: the name of the type being referenced (<i>G</i>)
   * 1: the number of type parameters that were declared
   * 2: the number of type arguments provided
   *
   * See [CompileTimeErrorCode.CONST_WITH_INVALID_TYPE_PARAMETERS], and
   * [CompileTimeErrorCode.NEW_WITH_INVALID_TYPE_PARAMETERS].
   */
  static const StaticTypeWarningCode WRONG_NUMBER_OF_TYPE_ARGUMENTS =
      const StaticTypeWarningCode('WRONG_NUMBER_OF_TYPE_ARGUMENTS',
          "The type '{0}' is declared with {1} type parameters, but {2} type arguments were given");

  /**
   * 17.16.1 Yield: Let T be the static type of e [the expression to the right
   * of "yield"] and let f be the immediately enclosing function.  It is a
   * static type warning if either:
   *
   * - the body of f is marked async* and the type Stream<T> may not be
   *   assigned to the declared return type of f.
   *
   * - the body of f is marked sync* and the type Iterable<T> may not be
   *   assigned to the declared return type of f.
   *
   * 17.16.2 Yield-Each: Let T be the static type of e [the expression to the
   * right of "yield*"] and let f be the immediately enclosing function.  It is
   * a static type warning if T may not be assigned to the declared return type
   * of f.  If f is synchronous it is a static type warning if T may not be
   * assigned to Iterable.  If f is asynchronous it is a static type warning if
   * T may not be assigned to Stream.
   */
  static const StaticTypeWarningCode YIELD_OF_INVALID_TYPE =
      const StaticTypeWarningCode('YIELD_OF_INVALID_TYPE',
          "The type '{0}' implied by the 'yield' expression must be assignable to '{1}'");

  /**
   * 17.6.2 For-in. If the iterable expression does not implement Iterable,
   * this warning is reported.
   *
   * Parameters:
   * 0: The type of the iterable expression.
   * 1: The sequence type -- Iterable for `for` or Stream for `await for`.
   */
  static const StaticTypeWarningCode FOR_IN_OF_INVALID_TYPE =
      const StaticTypeWarningCode('FOR_IN_OF_INVALID_TYPE',
          "The type '{0}' used in the 'for' loop must implement {1}");

  /**
   * 17.6.2 For-in. It the iterable expression does not implement Iterable with
   * a type argument that can be assigned to the for-in variable's type, this
   * warning is reported.
   *
   * Parameters:
   * 0: The type of the iterable expression.
   * 1: The sequence type -- Iterable for `for` or Stream for `await for`.
   * 2: The loop variable type.
   */
  static const StaticTypeWarningCode FOR_IN_OF_INVALID_ELEMENT_TYPE =
      const StaticTypeWarningCode('FOR_IN_OF_INVALID_ELEMENT_TYPE',
          "The type '{0}' used in the 'for' loop must implement {1} with a type argument that can be assigned to '{2}'");

  /**
   * Initialize a newly created error code to have the given [name]. The message
   * associated with the error will be created from the given [message]
   * template. The correction associated with the error will be created from the
   * given [correction] template.
   */
  const StaticTypeWarningCode(String name, String message, [String correction])
      : super(name, message, correction);

  @override
  ErrorSeverity get errorSeverity => ErrorType.STATIC_TYPE_WARNING.severity;

  @override
  ErrorType get type => ErrorType.STATIC_TYPE_WARNING;
}

/**
 * The error codes used for static warnings. The convention for this class is
 * for the name of the error code to indicate the problem that caused the error
 * to be generated and for the error message to explain what is wrong and, when
 * appropriate, how the problem can be corrected.
 */
class StaticWarningCode extends ErrorCode {
  /**
   * 14.1 Imports: If a name <i>N</i> is referenced by a library <i>L</i> and
   * <i>N</i> is introduced into the top level scope <i>L</i> by more than one
   * import then:
   * 1. A static warning occurs.
   * 2. If <i>N</i> is referenced as a function, getter or setter, a
   *    <i>NoSuchMethodError</i> is raised.
   * 3. If <i>N</i> is referenced as a type, it is treated as a malformed type.
   *
   * Parameters:
   * 0: the name of the ambiguous type
   * 1: the name of the first library that the type is found
   * 2: the name of the second library that the type is found
   */
  static const StaticWarningCode AMBIGUOUS_IMPORT = const StaticWarningCode(
      'AMBIGUOUS_IMPORT',
      "The name '{0}' is defined in the libraries {1}",
      "Consider using 'as prefix' for one of the import directives "
      "or hiding the name from all but one of the imports.");

  /**
   * 12.11.1 New: It is a static warning if the static type of <i>a<sub>i</sub>,
   * 1 &lt;= i &lt;= n+ k</i> may not be assigned to the type of the
   * corresponding formal parameter of the constructor <i>T.id</i> (respectively
   * <i>T</i>).
   *
   * 12.11.2 Const: It is a static warning if the static type of
   * <i>a<sub>i</sub>, 1 &lt;= i &lt;= n+ k</i> may not be assigned to the type
   * of the corresponding formal parameter of the constructor <i>T.id</i>
   * (respectively <i>T</i>).
   *
   * 12.14.2 Binding Actuals to Formals: Let <i>T<sub>i</sub></i> be the static
   * type of <i>a<sub>i</sub></i>, let <i>S<sub>i</sub></i> be the type of
   * <i>p<sub>i</sub>, 1 &lt;= i &lt;= n+k</i> and let <i>S<sub>q</sub></i> be
   * the type of the named parameter <i>q</i> of <i>f</i>. It is a static
   * warning if <i>T<sub>j</sub></i> may not be assigned to <i>S<sub>j</sub>, 1
   * &lt;= j &lt;= m</i>.
   *
   * 12.14.2 Binding Actuals to Formals: Furthermore, each <i>q<sub>i</sub>, 1
   * &lt;= i &lt;= l</i>, must have a corresponding named parameter in the set
   * <i>{p<sub>n+1</sub>, &hellip; p<sub>n+k</sub>}</i> or a static warning
   * occurs. It is a static warning if <i>T<sub>m+j</sub></i> may not be
   * assigned to <i>S<sub>r</sub></i>, where <i>r = q<sub>j</sub>, 1 &lt;= j
   * &lt;= l</i>.
   *
   * Parameters:
   * 0: the name of the actual argument type
   * 1: the name of the expected type
   */
  static const StaticWarningCode ARGUMENT_TYPE_NOT_ASSIGNABLE =
      shared_messages.ARGUMENT_TYPE_NOT_ASSIGNABLE_STATIC_WARNING;

  /**
   * 5 Variables: Attempting to assign to a final variable elsewhere will cause
   * a NoSuchMethodError to be thrown, because no setter is defined for it. The
   * assignment will also give rise to a static warning for the same reason.
   *
   * A constant variable is always implicitly final.
   */
  static const StaticWarningCode ASSIGNMENT_TO_CONST = const StaticWarningCode(
      'ASSIGNMENT_TO_CONST', "Constant variables cannot be assigned a value");

  /**
   * 5 Variables: Attempting to assign to a final variable elsewhere will cause
   * a NoSuchMethodError to be thrown, because no setter is defined for it. The
   * assignment will also give rise to a static warning for the same reason.
   */
  static const StaticWarningCode ASSIGNMENT_TO_FINAL = const StaticWarningCode(
      'ASSIGNMENT_TO_FINAL', "'{0}' cannot be used as a setter, it is final");

  /**
   * 5 Variables: Attempting to assign to a final variable elsewhere will cause
   * a NoSuchMethodError to be thrown, because no setter is defined for it. The
   * assignment will also give rise to a static warning for the same reason.
   */
  static const StaticWarningCode ASSIGNMENT_TO_FINAL_NO_SETTER =
      const StaticWarningCode('ASSIGNMENT_TO_FINAL_NO_SETTER',
          "No setter named '{0}' in class '{1}'");

  /**
   * 12.18 Assignment: It is as static warning if an assignment of the form
   * <i>v = e</i> occurs inside a top level or static function (be it function,
   * method, getter, or setter) or variable initializer and there is neither a
   * local variable declaration with name <i>v</i> nor setter declaration with
   * name <i>v=</i> in the lexical scope enclosing the assignment.
   */
  static const StaticWarningCode ASSIGNMENT_TO_FUNCTION =
      const StaticWarningCode(
          'ASSIGNMENT_TO_FUNCTION', "Functions cannot be assigned a value");

  /**
   * 12.18 Assignment: Let <i>T</i> be the static type of <i>e<sub>1</sub></i>
   * It is a static type warning if <i>T</i> does not have an accessible
   * instance setter named <i>v=</i>.
   */
  static const StaticWarningCode ASSIGNMENT_TO_METHOD = const StaticWarningCode(
      'ASSIGNMENT_TO_METHOD', "Methods cannot be assigned a value");

  /**
   * 12.18 Assignment: It is as static warning if an assignment of the form
   * <i>v = e</i> occurs inside a top level or static function (be it function,
   * method, getter, or setter) or variable initializer and there is neither a
   * local variable declaration with name <i>v</i> nor setter declaration with
   * name <i>v=</i> in the lexical scope enclosing the assignment.
   */
  static const StaticWarningCode ASSIGNMENT_TO_TYPE = const StaticWarningCode(
      'ASSIGNMENT_TO_TYPE', "Types cannot be assigned a value");

  /**
   * 13.9 Switch: It is a static warning if the last statement of the statement
   * sequence <i>s<sub>k</sub></i> is not a break, continue, return or throw
   * statement.
   */
  static const StaticWarningCode CASE_BLOCK_NOT_TERMINATED =
      const StaticWarningCode('CASE_BLOCK_NOT_TERMINATED',
          "The last statement of the 'case' should be 'break', 'continue', 'return' or 'throw'");

  /**
   * 12.32 Type Cast: It is a static warning if <i>T</i> does not denote a type
   * available in the current lexical scope.
   */
  static const StaticWarningCode CAST_TO_NON_TYPE = const StaticWarningCode(
      'CAST_TO_NON_TYPE',
      "The name '{0}' is not a type and cannot be used in an 'as' expression");

  /**
   * 7.4 Abstract Instance Members: It is a static warning if an abstract member
   * is declared or inherited in a concrete class.
   */
  static const StaticWarningCode CONCRETE_CLASS_WITH_ABSTRACT_MEMBER =
      const StaticWarningCode('CONCRETE_CLASS_WITH_ABSTRACT_MEMBER',
          "'{0}' must have a method body because '{1}' is not abstract");

  /**
   * 14.1 Imports: If a name <i>N</i> is referenced by a library <i>L</i> and
   * <i>N</i> would be introduced into the top level scope of <i>L</i> by an
   * import from a library whose URI begins with <i>dart:</i> and an import from
   * a library whose URI does not begin with <i>dart:</i>:
   * * The import from <i>dart:</i> is implicitly extended by a hide N clause.
   * * A static warning is issued.
   *
   * Parameters:
   * 0: the ambiguous name
   * 1: the name of the dart: library in which the element is found
   * 1: the name of the non-dart: library in which the element is found
   */
  static const StaticWarningCode CONFLICTING_DART_IMPORT =
      const StaticWarningCode('CONFLICTING_DART_IMPORT',
          "Element '{0}' from SDK library '{1}' is implicitly hidden by '{2}'");

  /**
   * 7.2 Getters: It is a static warning if a class <i>C</i> declares an
   * instance getter named <i>v</i> and an accessible static member named
   * <i>v</i> or <i>v=</i> is declared in a superclass of <i>C</i>.
   *
   * Parameters:
   * 0: the name of the super class declaring a static member
   */
  static const StaticWarningCode
      CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER =
      const StaticWarningCode(
          'CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER',
          "Superclass '{0}' declares static member with the same name");

  /**
   * 7.1 Instance Methods: It is a static warning if a class <i>C</i> declares
   * an instance method named <i>n</i> and has a setter named <i>n=</i>.
   */
  static const StaticWarningCode CONFLICTING_INSTANCE_METHOD_SETTER =
      const StaticWarningCode('CONFLICTING_INSTANCE_METHOD_SETTER',
          "Class '{0}' declares instance method '{1}', but also has a setter with the same name from '{2}'");

  /**
   * 7.1 Instance Methods: It is a static warning if a class <i>C</i> declares
   * an instance method named <i>n</i> and has a setter named <i>n=</i>.
   */
  static const StaticWarningCode CONFLICTING_INSTANCE_METHOD_SETTER2 =
      const StaticWarningCode('CONFLICTING_INSTANCE_METHOD_SETTER2',
          "Class '{0}' declares the setter '{1}', but also has an instance method in the same class");

  /**
   * 7.3 Setters: It is a static warning if a class <i>C</i> declares an
   * instance setter named <i>v=</i> and an accessible static member named
   * <i>v=</i> or <i>v</i> is declared in a superclass of <i>C</i>.
   *
   * Parameters:
   * 0: the name of the super class declaring a static member
   */
  static const StaticWarningCode
      CONFLICTING_INSTANCE_SETTER_AND_SUPERCLASS_MEMBER =
      const StaticWarningCode(
          'CONFLICTING_INSTANCE_SETTER_AND_SUPERCLASS_MEMBER',
          "Superclass '{0}' declares static member with the same name");

  /**
   * 7.2 Getters: It is a static warning if a class declares a static getter
   * named <i>v</i> and also has a non-static setter named <i>v=</i>.
   */
  static const StaticWarningCode CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER =
      const StaticWarningCode('CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER',
          "Class '{0}' declares non-static setter with the same name");

  /**
   * 7.3 Setters: It is a static warning if a class declares a static setter
   * named <i>v=</i> and also has a non-static member named <i>v</i>.
   */
  static const StaticWarningCode CONFLICTING_STATIC_SETTER_AND_INSTANCE_MEMBER =
      const StaticWarningCode('CONFLICTING_STATIC_SETTER_AND_INSTANCE_MEMBER',
          "Class '{0}' declares non-static member with the same name");

  /**
   * 12.11.2 Const: Given an instance creation expression of the form <i>const
   * q(a<sub>1</sub>, &hellip; a<sub>n</sub>)</i> it is a static warning if
   * <i>q</i> is the constructor of an abstract class but <i>q</i> is not a
   * factory constructor.
   */
  static const StaticWarningCode CONST_WITH_ABSTRACT_CLASS =
      const StaticWarningCode('CONST_WITH_ABSTRACT_CLASS',
          "Abstract classes cannot be created with a 'const' expression");

  /**
   * 12.7 Maps: It is a static warning if the values of any two keys in a map
   * literal are equal.
   */
  static const StaticWarningCode EQUAL_KEYS_IN_MAP = const StaticWarningCode(
      'EQUAL_KEYS_IN_MAP', "Keys in a map cannot be equal");

  /**
   * 14.2 Exports: It is a static warning to export two different libraries with
   * the same name.
   *
   * Parameters:
   * 0: the uri pointing to a first library
   * 1: the uri pointing to a second library
   * 2:e the shared name of the exported libraries
   */
  static const StaticWarningCode EXPORT_DUPLICATED_LIBRARY_NAMED =
      const StaticWarningCode('EXPORT_DUPLICATED_LIBRARY_NAMED',
          "The exported libraries '{0}' and '{1}' cannot have the same name '{2}'");

  /**
   * 12.14.2 Binding Actuals to Formals: It is a static warning if <i>m &lt;
   * h</i> or if <i>m &gt; n</i>.
   *
   * Parameters:
   * 0: the maximum number of positional arguments
   * 1: the actual number of positional arguments given
   *
   * See [NOT_ENOUGH_REQUIRED_ARGUMENTS].
   */
  static const StaticWarningCode EXTRA_POSITIONAL_ARGUMENTS =
      const StaticWarningCode('EXTRA_POSITIONAL_ARGUMENTS',
          "{0} positional arguments expected, but {1} found");

  /**
   * 5. Variables: It is a static warning if a final instance variable that has
   * been initialized at its point of declaration is also initialized in a
   * constructor.
   */
  static const StaticWarningCode
      FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION =
      const StaticWarningCode(
          'FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION',
          "Values cannot be set in the constructor if they are final, and have already been set");

  /**
   * 5. Variables: It is a static warning if a final instance variable that has
   * been initialized at its point of declaration is also initialized in a
   * constructor.
   *
   * Parameters:
   * 0: the name of the field in question
   */
  static const StaticWarningCode
      FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR =
      const StaticWarningCode(
          'FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR',
          "'{0}' is final and was given a value when it was declared, so it cannot be set to a new value");

  /**
   * 7.6.1 Generative Constructors: Execution of an initializer of the form
   * <b>this</b>.<i>v</i> = <i>e</i> proceeds as follows: First, the expression
   * <i>e</i> is evaluated to an object <i>o</i>. Then, the instance variable
   * <i>v</i> of the object denoted by this is bound to <i>o</i>.
   *
   * 12.14.2 Binding Actuals to Formals: Let <i>T<sub>i</sub></i> be the static
   * type of <i>a<sub>i</sub></i>, let <i>S<sub>i</sub></i> be the type of
   * <i>p<sub>i</sub>, 1 &lt;= i &lt;= n+k</i> and let <i>S<sub>q</sub></i> be
   * the type of the named parameter <i>q</i> of <i>f</i>. It is a static
   * warning if <i>T<sub>j</sub></i> may not be assigned to <i>S<sub>j</sub>, 1
   * &lt;= j &lt;= m</i>.
   *
   * Parameters:
   * 0: the name of the type of the initializer expression
   * 1: the name of the type of the field
   */
  static const StaticWarningCode FIELD_INITIALIZER_NOT_ASSIGNABLE =
      const StaticWarningCode('FIELD_INITIALIZER_NOT_ASSIGNABLE',
          "The initializer type '{0}' cannot be assigned to the field type '{1}'");

  /**
   * 7.6.1 Generative Constructors: An initializing formal has the form
   * <i>this.id</i>. It is a static warning if the static type of <i>id</i> is
   * not assignable to <i>T<sub>id</sub></i>.
   *
   * Parameters:
   * 0: the name of the type of the field formal parameter
   * 1: the name of the type of the field
   */
  static const StaticWarningCode FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE =
      const StaticWarningCode('FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE',
          "The parameter type '{0}' is incompatable with the field type '{1}'");

  /**
   * 5 Variables: It is a static warning if a library, static or local variable
   * <i>v</i> is final and <i>v</i> is not initialized at its point of
   * declaration.
   *
   * Parameters:
   * 0: the name of the uninitialized final variable
   */
  static const StaticWarningCode FINAL_NOT_INITIALIZED =
      const StaticWarningCode('FINAL_NOT_INITIALIZED',
          "The final variable '{0}' must be initialized", null, false);

  /**
   * 7.6.1 Generative Constructors: Each final instance variable <i>f</i>
   * declared in the immediately enclosing class must have an initializer in
   * <i>k</i>'s initializer list unless it has already been initialized by one
   * of the following means:
   * * Initialization at the declaration of <i>f</i>.
   * * Initialization by means of an initializing formal of <i>k</i>.
   * or a static warning occurs.
   *
   * Parameters:
   * 0: the name of the uninitialized final variable
   */
  static const StaticWarningCode FINAL_NOT_INITIALIZED_CONSTRUCTOR_1 =
      const StaticWarningCode('FINAL_NOT_INITIALIZED_CONSTRUCTOR_1',
          "The final variable '{0}' must be initialized", null, false);

  /**
   * 7.6.1 Generative Constructors: Each final instance variable <i>f</i>
   * declared in the immediately enclosing class must have an initializer in
   * <i>k</i>'s initializer list unless it has already been initialized by one
   * of the following means:
   * * Initialization at the declaration of <i>f</i>.
   * * Initialization by means of an initializing formal of <i>k</i>.
   * or a static warning occurs.
   *
   * Parameters:
   * 0: the name of the uninitialized final variable
   * 1: the name of the uninitialized final variable
   */
  static const StaticWarningCode FINAL_NOT_INITIALIZED_CONSTRUCTOR_2 =
      const StaticWarningCode(
          'FINAL_NOT_INITIALIZED_CONSTRUCTOR_2',
          "The final variables '{0}' and '{1}' must be initialized",
          null,
          false);

  /**
   * 7.6.1 Generative Constructors: Each final instance variable <i>f</i>
   * declared in the immediately enclosing class must have an initializer in
   * <i>k</i>'s initializer list unless it has already been initialized by one
   * of the following means:
   * * Initialization at the declaration of <i>f</i>.
   * * Initialization by means of an initializing formal of <i>k</i>.
   * or a static warning occurs.
   *
   * Parameters:
   * 0: the name of the uninitialized final variable
   * 1: the name of the uninitialized final variable
   * 2: the number of additional not initialized variables that aren't listed
   */
  static const StaticWarningCode FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS =
      const StaticWarningCode(
          'FINAL_NOT_INITIALIZED_CONSTRUCTOR_3',
          "The final variables '{0}', '{1}' and '{2}' more must be initialized",
          null,
          false);

  /**
   * 15.5 Function Types: It is a static warning if a concrete class implements
   * Function and does not have a concrete method named call().
   */
  static const StaticWarningCode FUNCTION_WITHOUT_CALL = const StaticWarningCode(
      'FUNCTION_WITHOUT_CALL',
      "Concrete classes that implement Function must implement the method call()");

  /**
   * 14.1 Imports: It is a static warning to import two different libraries with
   * the same name.
   *
   * Parameters:
   * 0: the uri pointing to a first library
   * 1: the uri pointing to a second library
   * 2: the shared name of the imported libraries
   */
  static const StaticWarningCode IMPORT_DUPLICATED_LIBRARY_NAMED =
      const StaticWarningCode('IMPORT_DUPLICATED_LIBRARY_NAMED',
          "The imported libraries '{0}' and '{1}' cannot have the same name '{2}'");

  /**
   * 14.1 Imports: It is a static warning if the specified URI of a deferred
   * import does not refer to a library declaration.
   *
   * Parameters:
   * 0: the uri pointing to a non-library declaration
   *
   * See [CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY].
   */
  static const StaticWarningCode IMPORT_OF_NON_LIBRARY =
      const StaticWarningCode('IMPORT_OF_NON_LIBRARY',
          "The imported library '{0}' must not have a part-of directive");

  /**
   * 8.1.1 Inheritance and Overriding: However, if the above rules would cause
   * multiple members <i>m<sub>1</sub>, &hellip;, m<sub>k</sub></i> with the
   * same name <i>n</i> that would be inherited (because identically named
   * members existed in several superinterfaces) then at most one member is
   * inherited.
   *
   * If some but not all of the <i>m<sub>i</sub>, 1 &lt;= i &lt;= k</i> are
   * getters none of the <i>m<sub>i</sub></i> are inherited, and a static
   * warning is issued.
   */
  static const StaticWarningCode
      INCONSISTENT_METHOD_INHERITANCE_GETTER_AND_METHOD =
      const StaticWarningCode(
          'INCONSISTENT_METHOD_INHERITANCE_GETTER_AND_METHOD',
          "'{0}' is inherited as a getter and also a method");

  /**
   * 7.1 Instance Methods: It is a static warning if a class <i>C</i> declares
   * an instance method named <i>n</i> and an accessible static member named
   * <i>n</i> is declared in a superclass of <i>C</i>.
   *
   * Parameters:
   * 0: the name of the member with the name conflict
   * 1: the name of the enclosing class that has the static member
   */
  static const StaticWarningCode
      INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC =
      const StaticWarningCode(
          'INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC',
          "'{0}' collides with a static member in the superclass '{1}'");

  /**
   * 7.2 Getters: It is a static warning if a getter <i>m1</i> overrides a
   * getter <i>m2</i> and the type of <i>m1</i> is not a subtype of the type of
   * <i>m2</i>.
   *
   * Parameters:
   * 0: the name of the actual return type
   * 1: the name of the expected return type, not assignable to the actual
   *    return type
   * 2: the name of the class where the overridden getter is declared
   *
   * See [INVALID_METHOD_OVERRIDE_RETURN_TYPE].
   */
  static const StaticWarningCode INVALID_GETTER_OVERRIDE_RETURN_TYPE =
      const StaticWarningCode('INVALID_GETTER_OVERRIDE_RETURN_TYPE',
          "The return type '{0}' is not assignable to '{1}' as required by the getter it is overriding from '{2}'");

  /**
   * 7.1 Instance Methods: It is a static warning if an instance method
   * <i>m1</i> overrides an instance method <i>m2</i> and the type of <i>m1</i>
   * is not a subtype of the type of <i>m2</i>.
   *
   * Parameters:
   * 0: the name of the actual parameter type
   * 1: the name of the expected parameter type, not assignable to the actual
   *    parameter type
   * 2: the name of the class where the overridden method is declared
   */
  static const StaticWarningCode INVALID_METHOD_OVERRIDE_NAMED_PARAM_TYPE =
      const StaticWarningCode('INVALID_METHOD_OVERRIDE_NAMED_PARAM_TYPE',
          "The parameter type '{0}' is not assignable to '{1}' as required by the method it is overriding from '{2}'");

  /**
   * Generic Method DEP: number of type parameters must match.
   * <https://github.com/leafpetersen/dep-generic-methods/blob/master/proposal.md#function-subtyping>
   *
   * Parameters:
   * 0: the number of type parameters in the method
   * 1: the number of type parameters in the overridden method
   * 2: the name of the class where the overridden method is declared
   */
  static const StaticWarningCode INVALID_METHOD_OVERRIDE_TYPE_PARAMETERS =
      const StaticWarningCode('INVALID_METHOD_OVERRIDE_TYPE_PARAMETERS',
          "The method has {0} type parameters, but it is overriding a method with {1} type parameters from '{2}'");

  /**
   * Generic Method DEP: bounds of type parameters must be compatible.
   * <https://github.com/leafpetersen/dep-generic-methods/blob/master/proposal.md#function-subtyping>
   *
   * Parameters:
   * 0: the type parameter name
   * 1: the type parameter bound
   * 2: the overridden type parameter name
   * 3: the overridden type parameter bound
   * 4: the name of the class where the overridden method is declared
   */
  static const StaticWarningCode INVALID_METHOD_OVERRIDE_TYPE_PARAMETER_BOUND =
      const StaticWarningCode('INVALID_METHOD_OVERRIDE_TYPE_PARAMETER_BOUND',
          "The type parameter '{0}' extends '{1}', but that is stricter than '{2}' extends '{3}' in the overridden method from '{4}'");

  /**
   * 7.1 Instance Methods: It is a static warning if an instance method
   * <i>m1</i> overrides an instance method <i>m2</i> and the type of <i>m1</i>
   * is not a subtype of the type of <i>m2</i>.
   *
   * Parameters:
   * 0: the name of the actual parameter type
   * 1: the name of the expected parameter type, not assignable to the actual
   *    parameter type
   * 2: the name of the class where the overridden method is declared
   * See [INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE].
   */
  static const StaticWarningCode INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE =
      const StaticWarningCode('INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE',
          "The parameter type '{0}' is not assignable to '{1}' as required by the method it is overriding from '{2}'");

  /**
   * 7.1 Instance Methods: It is a static warning if an instance method
   * <i>m1</i> overrides an instance method <i>m2</i> and the type of <i>m1</i>
   * is not a subtype of the type of <i>m2</i>.
   *
   * Parameters:
   * 0: the name of the actual parameter type
   * 1: the name of the expected parameter type, not assignable to the actual
   *    parameter type
   * 2: the name of the class where the overridden method is declared
   */
  static const StaticWarningCode INVALID_METHOD_OVERRIDE_OPTIONAL_PARAM_TYPE =
      const StaticWarningCode('INVALID_METHOD_OVERRIDE_OPTIONAL_PARAM_TYPE',
          "The parameter type '{0}' is not assignable to '{1}' as required by the method it is overriding from '{2}'");

  /**
   * 7.1 Instance Methods: It is a static warning if an instance method
   * <i>m1</i> overrides an instance method <i>m2</i> and the type of <i>m1</i>
   * is not a subtype of the type of <i>m2</i>.
   *
   * Parameters:
   * 0: the name of the actual return type
   * 1: the name of the expected return type, not assignable to the actual
   *    return type
   * 2: the name of the class where the overridden method is declared
   *
   * See [INVALID_GETTER_OVERRIDE_RETURN_TYPE].
   */
  static const StaticWarningCode INVALID_METHOD_OVERRIDE_RETURN_TYPE =
      const StaticWarningCode('INVALID_METHOD_OVERRIDE_RETURN_TYPE',
          "The return type '{0}' is not assignable to '{1}' as required by the method it is overriding from '{2}'");

  /**
   * 7.1 Instance Methods: It is a static warning if an instance method
   * <i>m1</i> overrides an instance member <i>m2</i>, the signature of
   * <i>m2</i> explicitly specifies a default value for a formal parameter
   * <i>p</i> and the signature of <i>m1</i> specifies a different default value
   * for <i>p</i>.
   */
  static const StaticWarningCode
      INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED = const StaticWarningCode(
          'INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED',
          "Parameters cannot override default values, this method overrides '{0}.{1}' where '{2}' has a different value");

  /**
   * 7.1 Instance Methods: It is a static warning if an instance method
   * <i>m1</i> overrides an instance member <i>m2</i>, the signature of
   * <i>m2</i> explicitly specifies a default value for a formal parameter
   * <i>p</i> and the signature of <i>m1</i> specifies a different default value
   * for <i>p</i>.
   */
  static const StaticWarningCode
      INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL =
      const StaticWarningCode(
          'INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL',
          "Parameters cannot override default values, this method overrides '{0}.{1}' where this positional parameter has a different value");

  /**
   * 7.1 Instance Methods: It is a static warning if an instance method
   * <i>m1</i> overrides an instance member <i>m2</i> and <i>m1</i> does not
   * declare all the named parameters declared by <i>m2</i>.
   *
   * Parameters:
   * 0: the number of named parameters in the overridden member
   * 1: the signature of the overridden member
   * 2: the name of the class from the overridden method
   */
  static const StaticWarningCode INVALID_OVERRIDE_NAMED = const StaticWarningCode(
      'INVALID_OVERRIDE_NAMED',
      "Missing the named parameter '{0}' to match the overridden method from '{1}' from '{2}'");

  /**
   * 7.1 Instance Methods: It is a static warning if an instance method
   * <i>m1</i> overrides an instance member <i>m2</i> and <i>m1</i> has fewer
   * positional parameters than <i>m2</i>.
   *
   * Parameters:
   * 0: the number of positional parameters in the overridden member
   * 1: the signature of the overridden member
   * 2: the name of the class from the overridden method
   */
  static const StaticWarningCode INVALID_OVERRIDE_POSITIONAL =
      const StaticWarningCode('INVALID_OVERRIDE_POSITIONAL',
          "Must have at least {0} parameters to match the overridden method '{1}' from '{2}'");

  /**
   * 7.1 Instance Methods: It is a static warning if an instance method
   * <i>m1</i> overrides an instance member <i>m2</i> and <i>m1</i> has a
   * greater number of required parameters than <i>m2</i>.
   *
   * Parameters:
   * 0: the number of required parameters in the overridden member
   * 1: the signature of the overridden member
   * 2: the name of the class from the overridden method
   */
  static const StaticWarningCode INVALID_OVERRIDE_REQUIRED =
      const StaticWarningCode('INVALID_OVERRIDE_REQUIRED',
          "Must have {0} required parameters or less to match the overridden method '{1}' from '{2}'");

  /**
   * 7.3 Setters: It is a static warning if a setter <i>m1</i> overrides a
   * setter <i>m2</i> and the type of <i>m1</i> is not a subtype of the type of
   * <i>m2</i>.
   *
   * Parameters:
   * 0: the name of the actual parameter type
   * 1: the name of the expected parameter type, not assignable to the actual
   * parameter type
   * 2: the name of the class where the overridden setter is declared
   *
   * See [INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE].
   */
  static const StaticWarningCode INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE =
      const StaticWarningCode('INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE',
          "The parameter type '{0}' is not assignable to '{1}' as required by the setter it is overriding from '{2}'");

  /**
   * 12.6 Lists: A run-time list literal &lt;<i>E</i>&gt; [<i>e<sub>1</sub></i>
   * &hellip; <i>e<sub>n</sub></i>] is evaluated as follows:
   * * The operator []= is invoked on <i>a</i> with first argument <i>i</i> and
   *   second argument <i>o<sub>i+1</sub></i><i>, 1 &lt;= i &lt;= n</i>
   *
   * 12.14.2 Binding Actuals to Formals: Let <i>T<sub>i</sub></i> be the static
   * type of <i>a<sub>i</sub></i>, let <i>S<sub>i</sub></i> be the type of
   * <i>p<sub>i</sub>, 1 &lt;= i &lt;= n+k</i> and let <i>S<sub>q</sub></i> be
   * the type of the named parameter <i>q</i> of <i>f</i>. It is a static
   * warning if <i>T<sub>j</sub></i> may not be assigned to <i>S<sub>j</sub>, 1
   * &lt;= j &lt;= m</i>.
   */
  static const StaticWarningCode LIST_ELEMENT_TYPE_NOT_ASSIGNABLE =
      const StaticWarningCode('LIST_ELEMENT_TYPE_NOT_ASSIGNABLE',
          "The element type '{0}' cannot be assigned to the list type '{1}'");

  /**
   * 12.7 Map: A run-time map literal &lt;<i>K</i>, <i>V</i>&gt;
   * [<i>k<sub>1</sub></i> : <i>e<sub>1</sub></i> &hellip; <i>k<sub>n</sub></i>
   * : <i>e<sub>n</sub></i>] is evaluated as follows:
   * * The operator []= is invoked on <i>m</i> with first argument
   *   <i>k<sub>i</sub></i> and second argument <i>e<sub>i</sub></i><i>, 1 &lt;=
   *   i &lt;= n</i>
   *
   * 12.14.2 Binding Actuals to Formals: Let <i>T<sub>i</sub></i> be the static
   * type of <i>a<sub>i</sub></i>, let <i>S<sub>i</sub></i> be the type of
   * <i>p<sub>i</sub>, 1 &lt;= i &lt;= n+k</i> and let <i>S<sub>q</sub></i> be
   * the type of the named parameter <i>q</i> of <i>f</i>. It is a static
   * warning if <i>T<sub>j</sub></i> may not be assigned to <i>S<sub>j</sub>, 1
   * &lt;= j &lt;= m</i>.
   */
  static const StaticWarningCode MAP_KEY_TYPE_NOT_ASSIGNABLE =
      const StaticWarningCode('MAP_KEY_TYPE_NOT_ASSIGNABLE',
          "The element type '{0}' cannot be assigned to the map key type '{1}'");

  /**
   * 12.7 Map: A run-time map literal &lt;<i>K</i>, <i>V</i>&gt;
   * [<i>k<sub>1</sub></i> : <i>e<sub>1</sub></i> &hellip; <i>k<sub>n</sub></i>
   * : <i>e<sub>n</sub></i>] is evaluated as follows:
   * * The operator []= is invoked on <i>m</i> with first argument
   *   <i>k<sub>i</sub></i> and second argument <i>e<sub>i</sub></i><i>, 1 &lt;=
   *   i &lt;= n</i>
   *
   * 12.14.2 Binding Actuals to Formals: Let <i>T<sub>i</sub></i> be the static
   * type of <i>a<sub>i</sub></i>, let <i>S<sub>i</sub></i> be the type of
   * <i>p<sub>i</sub>, 1 &lt;= i &lt;= n+k</i> and let <i>S<sub>q</sub></i> be
   * the type of the named parameter <i>q</i> of <i>f</i>. It is a static
   * warning if <i>T<sub>j</sub></i> may not be assigned to <i>S<sub>j</sub>, 1
   * &lt;= j &lt;= m</i>.
   */
  static const StaticWarningCode MAP_VALUE_TYPE_NOT_ASSIGNABLE =
      const StaticWarningCode('MAP_VALUE_TYPE_NOT_ASSIGNABLE',
          "The element type '{0}' cannot be assigned to the map value type '{1}'");

  /**
   * 7.3 Setters: It is a static warning if a class has a setter named <i>v=</i>
   * with argument type <i>T</i> and a getter named <i>v</i> with return type
   * <i>S</i>, and <i>T</i> may not be assigned to <i>S</i>.
   */
  static const StaticWarningCode MISMATCHED_GETTER_AND_SETTER_TYPES =
      const StaticWarningCode(
          'MISMATCHED_GETTER_AND_SETTER_TYPES',
          "The parameter type for setter '{0}' is '{1}' which is not assignable to its getter (of type '{2}')",
          null,
          false);

  /**
   * 7.3 Setters: It is a static warning if a class has a setter named <i>v=</i>
   * with argument type <i>T</i> and a getter named <i>v</i> with return type
   * <i>S</i>, and <i>T</i> may not be assigned to <i>S</i>.
   */
  static const StaticWarningCode
      MISMATCHED_GETTER_AND_SETTER_TYPES_FROM_SUPERTYPE =
      const StaticWarningCode(
          'MISMATCHED_GETTER_AND_SETTER_TYPES_FROM_SUPERTYPE',
          "The parameter type for setter '{0}' is '{1}' which is not assignable to its getter (of type '{2}'), from superclass '{3}'",
          null,
          false);

  /**
   * 17.9 Switch: It is a static warning if all of the following conditions
   * hold:
   * * The switch statement does not have a 'default' clause.
   * * The static type of <i>e</i> is an enumerated typed with elements
   *   <i>id<sub>1</sub></i>, &hellip;, <i>id<sub>n</sub></i>.
   * * The sets {<i>e<sub>1</sub></i>, &hellip;, <i>e<sub>k</sub></i>} and
   *   {<i>id<sub>1</sub></i>, &hellip;, <i>id<sub>n</sub></i>} are not the
   *   same.
   *
   * Parameters:
   * 0: the name of the constant that is missing
   */
  static const StaticWarningCode MISSING_ENUM_CONSTANT_IN_SWITCH =
      const StaticWarningCode(
          'MISSING_ENUM_CONSTANT_IN_SWITCH',
          "Missing case clause for '{0}'",
          "Add a case clause for the missing constant or add a default clause.",
          false);

  /**
   * 13.12 Return: It is a static warning if a function contains both one or
   * more return statements of the form <i>return;</i> and one or more return
   * statements of the form <i>return e;</i>.
   */
  static const StaticWarningCode MIXED_RETURN_TYPES = const StaticWarningCode(
      'MIXED_RETURN_TYPES',
      "Methods and functions cannot use return both with and without values",
      null,
      false);

  /**
   * 12.11.1 New: It is a static warning if <i>q</i> is a constructor of an
   * abstract class and <i>q</i> is not a factory constructor.
   */
  static const StaticWarningCode NEW_WITH_ABSTRACT_CLASS =
      const StaticWarningCode('NEW_WITH_ABSTRACT_CLASS',
          "Abstract classes cannot be created with a 'new' expression");

  /**
   * 15.8 Parameterized Types: Any use of a malbounded type gives rise to a
   * static warning.
   *
   * Parameters:
   * 0: the name of the type being referenced (<i>S</i>)
   * 1: the number of type parameters that were declared
   * 2: the number of type arguments provided
   *
   * See [CompileTimeErrorCode.CONST_WITH_INVALID_TYPE_PARAMETERS], and
   * [StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS].
   */
  static const StaticWarningCode NEW_WITH_INVALID_TYPE_PARAMETERS =
      const StaticWarningCode('NEW_WITH_INVALID_TYPE_PARAMETERS',
          "The type '{0}' is declared with {1} type parameters, but {2} type arguments were given");

  /**
   * 12.11.1 New: It is a static warning if <i>T</i> is not a class accessible
   * in the current scope, optionally followed by type arguments.
   *
   * Parameters:
   * 0: the name of the non-type element
   */
  static const StaticWarningCode NEW_WITH_NON_TYPE = const StaticWarningCode(
      'NEW_WITH_NON_TYPE', "The name '{0}' is not a class");

  /**
   * 12.11.1 New: If <i>T</i> is a class or parameterized type accessible in the
   * current scope then:
   * 1. If <i>e</i> is of the form <i>new T.id(a<sub>1</sub>, &hellip;,
   *    a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;,
   *    x<sub>n+k</sub>: a<sub>n+k</sub>)</i> it is a static warning if
   *    <i>T.id</i> is not the name of a constructor declared by the type
   *    <i>T</i>.
   * If <i>e</i> of the form <i>new T(a<sub>1</sub>, &hellip;, a<sub>n</sub>,
   * x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;, x<sub>n+k</sub>:
   * a<sub>n+kM/sub>)</i> it is a static warning if the type <i>T</i> does not
   * declare a constructor with the same name as the declaration of <i>T</i>.
   */
  static const StaticWarningCode NEW_WITH_UNDEFINED_CONSTRUCTOR =
      const StaticWarningCode('NEW_WITH_UNDEFINED_CONSTRUCTOR',
          "The class '{0}' does not have a constructor '{1}'");

  /**
   * 12.11.1 New: If <i>T</i> is a class or parameterized type accessible in the
   * current scope then:
   * 1. If <i>e</i> is of the form <i>new T.id(a<sub>1</sub>, &hellip;,
   * a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;, x<sub>n+k</sub>:
   * a<sub>n+k</sub>)</i> it is a static warning if <i>T.id</i> is not the name
   * of a constructor declared by the type <i>T</i>. If <i>e</i> of the form
   * <i>new T(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>:
   * a<sub>n+1</sub>, &hellip;, x<sub>n+k</sub>: a<sub>n+kM/sub>)</i> it is a
   * static warning if the type <i>T</i> does not declare a constructor with the
   * same name as the declaration of <i>T</i>.
   */
  static const StaticWarningCode NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT =
      const StaticWarningCode('NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT',
          "The class '{0}' does not have a default constructor");

  /**
   * 7.9.1 Inheritance and Overriding: It is a static warning if a non-abstract
   * class inherits an abstract method.
   *
   * 7.10 Superinterfaces: Let <i>C</i> be a concrete class that does not
   * declare its own <i>noSuchMethod()</i> method. It is a static warning if the
   * implicit interface of <i>C</i> includes an instance member <i>m</i> of type
   * <i>F</i> and <i>C</i> does not declare or inherit a corresponding instance
   * member <i>m</i> of type <i>F'</i> such that <i>F' <: F</i>.
   *
   * 7.4 Abstract Instance Members: It is a static warning if an abstract member
   * is declared or inherited in a concrete class unless that member overrides a
   * concrete one.
   *
   * Parameters:
   * 0: the name of the first member
   * 1: the name of the second member
   * 2: the name of the third member
   * 3: the name of the fourth member
   * 4: the number of additional missing members that aren't listed
   */
  static const StaticWarningCode
      NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS =
      const StaticWarningCode(
          'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS',
          "Missing concrete implementation of {0}, {1}, {2}, {3} and {4} more");

  /**
   * 7.9.1 Inheritance and Overriding: It is a static warning if a non-abstract
   * class inherits an abstract method.
   *
   * 7.10 Superinterfaces: Let <i>C</i> be a concrete class that does not
   * declare its own <i>noSuchMethod()</i> method. It is a static warning if the
   * implicit interface of <i>C</i> includes an instance member <i>m</i> of type
   * <i>F</i> and <i>C</i> does not declare or inherit a corresponding instance
   * member <i>m</i> of type <i>F'</i> such that <i>F' <: F</i>.
   *
   * 7.4 Abstract Instance Members: It is a static warning if an abstract member
   * is declared or inherited in a concrete class unless that member overrides a
   * concrete one.
   *
   * Parameters:
   * 0: the name of the first member
   * 1: the name of the second member
   * 2: the name of the third member
   * 3: the name of the fourth member
   */
  static const StaticWarningCode
      NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR =
      const StaticWarningCode(
          'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR',
          "Missing concrete implementation of {0}, {1}, {2} and {3}");

  /**
   * 7.9.1 Inheritance and Overriding: It is a static warning if a non-abstract
   * class inherits an abstract method.
   *
   * 7.10 Superinterfaces: Let <i>C</i> be a concrete class that does not
   * declare its own <i>noSuchMethod()</i> method. It is a static warning if the
   * implicit interface of <i>C</i> includes an instance member <i>m</i> of type
   * <i>F</i> and <i>C</i> does not declare or inherit a corresponding instance
   * member <i>m</i> of type <i>F'</i> such that <i>F' <: F</i>.
   *
   * 7.4 Abstract Instance Members: It is a static warning if an abstract member
   * is declared or inherited in a concrete class unless that member overrides a
   * concrete one.
   *
   * Parameters:
   * 0: the name of the member
   */
  static const StaticWarningCode
      NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE = const StaticWarningCode(
          'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE',
          "Missing concrete implementation of {0}");

  /**
   * 7.9.1 Inheritance and Overriding: It is a static warning if a non-abstract
   * class inherits an abstract method.
   *
   * 7.10 Superinterfaces: Let <i>C</i> be a concrete class that does not
   * declare its own <i>noSuchMethod()</i> method. It is a static warning if the
   * implicit interface of <i>C</i> includes an instance member <i>m</i> of type
   * <i>F</i> and <i>C</i> does not declare or inherit a corresponding instance
   * member <i>m</i> of type <i>F'</i> such that <i>F' <: F</i>.
   *
   * 7.4 Abstract Instance Members: It is a static warning if an abstract member
   * is declared or inherited in a concrete class unless that member overrides a
   * concrete one.
   *
   * Parameters:
   * 0: the name of the first member
   * 1: the name of the second member
   * 2: the name of the third member
   */
  static const StaticWarningCode
      NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE =
      const StaticWarningCode(
          'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE',
          "Missing concrete implementation of {0}, {1} and {2}");

  /**
   * 7.9.1 Inheritance and Overriding: It is a static warning if a non-abstract
   * class inherits an abstract method.
   *
   * 7.10 Superinterfaces: Let <i>C</i> be a concrete class that does not
   * declare its own <i>noSuchMethod()</i> method. It is a static warning if the
   * implicit interface of <i>C</i> includes an instance member <i>m</i> of type
   * <i>F</i> and <i>C</i> does not declare or inherit a corresponding instance
   * member <i>m</i> of type <i>F'</i> such that <i>F' <: F</i>.
   *
   * 7.4 Abstract Instance Members: It is a static warning if an abstract member
   * is declared or inherited in a concrete class unless that member overrides a
   * concrete one.
   *
   * Parameters:
   * 0: the name of the first member
   * 1: the name of the second member
   */
  static const StaticWarningCode
      NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO = const StaticWarningCode(
          'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO',
          "Missing concrete implementation of {0} and {1}");

  /**
   * 13.11 Try: An on-catch clause of the form <i>on T catch (p<sub>1</sub>,
   * p<sub>2</sub>) s</i> or <i>on T s</i> matches an object <i>o</i> if the
   * type of <i>o</i> is a subtype of <i>T</i>. It is a static warning if
   * <i>T</i> does not denote a type available in the lexical scope of the
   * catch clause.
   *
   * Parameters:
   * 0: the name of the non-type element
   */
  static const StaticWarningCode NON_TYPE_IN_CATCH_CLAUSE =
      const StaticWarningCode('NON_TYPE_IN_CATCH_CLAUSE',
          "The name '{0}' is not a type and cannot be used in an on-catch clause");

  /**
   * 7.1.1 Operators: It is a static warning if the return type of the
   * user-declared operator []= is explicitly declared and not void.
   */
  static const StaticWarningCode NON_VOID_RETURN_FOR_OPERATOR =
      const StaticWarningCode('NON_VOID_RETURN_FOR_OPERATOR',
          "The return type of the operator []= must be 'void'", null, false);

  /**
   * 7.3 Setters: It is a static warning if a setter declares a return type
   * other than void.
   */
  static const StaticWarningCode NON_VOID_RETURN_FOR_SETTER =
      const StaticWarningCode('NON_VOID_RETURN_FOR_SETTER',
          "The return type of the setter must be 'void'", null, false);

  /**
   * 15.1 Static Types: A type <i>T</i> is malformed iff:
   * * <i>T</i> has the form <i>id</i> or the form <i>prefix.id</i>, and in the
   *   enclosing lexical scope, the name <i>id</i> (respectively
   *   <i>prefix.id</i>) does not denote a type.
   * * <i>T</i> denotes a type parameter in the enclosing lexical scope, but
   * occurs in the signature or body of a static member.
   * * <i>T</i> is a parameterized type of the form <i>G&lt;S<sub>1</sub>, ..,
   * S<sub>n</sub>&gt;</i>,
   *
   * Any use of a malformed type gives rise to a static warning.
   *
   * Parameters:
   * 0: the name that is not a type
   */
  static const StaticWarningCode NOT_A_TYPE =
      const StaticWarningCode('NOT_A_TYPE', "{0} is not a type");

  /**
   * 12.14.2 Binding Actuals to Formals: It is a static warning if <i>m &lt;
   * h</i> or if <i>m &gt; n</i>.
   *
   * Parameters:
   * 0: the expected number of required arguments
   * 1: the actual number of positional arguments given
   *
   * See [EXTRA_POSITIONAL_ARGUMENTS].
   */
  static const StaticWarningCode NOT_ENOUGH_REQUIRED_ARGUMENTS =
      const StaticWarningCode('NOT_ENOUGH_REQUIRED_ARGUMENTS',
          "{0} required argument(s) expected, but {1} found");

  /**
   * 14.3 Parts: It is a static warning if the referenced part declaration
   * <i>p</i> names a library other than the current library as the library to
   * which <i>p</i> belongs.
   *
   * Parameters:
   * 0: the name of expected library name
   * 1: the non-matching actual library name from the "part of" declaration
   */
  static const StaticWarningCode PART_OF_DIFFERENT_LIBRARY =
      const StaticWarningCode('PART_OF_DIFFERENT_LIBRARY',
          "Expected this library to be part of '{0}', not '{1}'");

  /**
   * 7.6.2 Factories: It is a static warning if the function type of <i>k'</i>
   * is not a subtype of the type of <i>k</i>.
   *
   * Parameters:
   * 0: the name of the redirected constructor
   * 1: the name of the redirecting constructor
   */
  static const StaticWarningCode REDIRECT_TO_INVALID_FUNCTION_TYPE =
      const StaticWarningCode('REDIRECT_TO_INVALID_FUNCTION_TYPE',
          "The redirected constructor '{0}' has incompatible parameters with '{1}'");

  /**
   * 7.6.2 Factories: It is a static warning if the function type of <i>k'</i>
   * is not a subtype of the type of <i>k</i>.
   *
   * Parameters:
   * 0: the name of the redirected constructor return type
   * 1: the name of the redirecting constructor return type
   */
  static const StaticWarningCode REDIRECT_TO_INVALID_RETURN_TYPE =
      const StaticWarningCode('REDIRECT_TO_INVALID_RETURN_TYPE',
          "The return type '{0}' of the redirected constructor is not assignable to '{1}'");

  /**
   * 7.6.2 Factories: It is a static warning if type does not denote a class
   * accessible in the current scope; if type does denote such a class <i>C</i>
   * it is a static warning if the referenced constructor (be it <i>type</i> or
   * <i>type.id</i>) is not a constructor of <i>C</i>.
   */
  static const StaticWarningCode REDIRECT_TO_MISSING_CONSTRUCTOR =
      const StaticWarningCode('REDIRECT_TO_MISSING_CONSTRUCTOR',
          "The constructor '{0}' could not be found in '{1}'");

  /**
   * 7.6.2 Factories: It is a static warning if type does not denote a class
   * accessible in the current scope; if type does denote such a class <i>C</i>
   * it is a static warning if the referenced constructor (be it <i>type</i> or
   * <i>type.id</i>) is not a constructor of <i>C</i>.
   */
  static const StaticWarningCode REDIRECT_TO_NON_CLASS = const StaticWarningCode(
      'REDIRECT_TO_NON_CLASS',
      "The name '{0}' is not a type and cannot be used in a redirected constructor");

  /**
   * 13.12 Return: Let <i>f</i> be the function immediately enclosing a return
   * statement of the form <i>return;</i> It is a static warning if both of the
   * following conditions hold:
   * * <i>f</i> is not a generative constructor.
   * * The return type of <i>f</i> may not be assigned to void.
   */
  static const StaticWarningCode RETURN_WITHOUT_VALUE = const StaticWarningCode(
      'RETURN_WITHOUT_VALUE',
      "Missing return value after 'return'",
      null,
      false);

  /**
   * 12.16.3 Static Invocation: It is a static warning if <i>C</i> does not
   * declare a static method or getter <i>m</i>.
   *
   * Parameters:
   * 0: the name of the instance member
   */
  static const StaticWarningCode STATIC_ACCESS_TO_INSTANCE_MEMBER =
      const StaticWarningCode('STATIC_ACCESS_TO_INSTANCE_MEMBER',
          "Instance member '{0}' cannot be accessed using static access");

  /**
   * 13.9 Switch: It is a static warning if the type of <i>e</i> may not be
   * assigned to the type of <i>e<sub>k</sub></i>.
   */
  static const StaticWarningCode SWITCH_EXPRESSION_NOT_ASSIGNABLE =
      const StaticWarningCode('SWITCH_EXPRESSION_NOT_ASSIGNABLE',
          "Type '{0}' of the switch expression is not assignable to the type '{1}' of case expressions");

  /**
   * 15.1 Static Types: It is a static warning to use a deferred type in a type
   * annotation.
   *
   * Parameters:
   * 0: the name of the type that is deferred and being used in a type
   *    annotation
   */
  static const StaticWarningCode TYPE_ANNOTATION_DEFERRED_CLASS =
      const StaticWarningCode('TYPE_ANNOTATION_DEFERRED_CLASS',
          "The deferred type '{0}' cannot be used in a declaration, cast or type test");

  /**
   * 12.31 Type Test: It is a static warning if <i>T</i> does not denote a type
   * available in the current lexical scope.
   */
  static const StaticWarningCode TYPE_TEST_WITH_NON_TYPE = const StaticWarningCode(
      'TYPE_TEST_WITH_NON_TYPE',
      "The name '{0}' is not a type and cannot be used in an 'is' expression");

  /**
   * 12.31 Type Test: It is a static warning if <i>T</i> does not denote a type
   * available in the current lexical scope.
   */
  static const StaticWarningCode TYPE_TEST_WITH_UNDEFINED_NAME =
      const StaticWarningCode('TYPE_TEST_WITH_UNDEFINED_NAME',
          "The name '{0}' is not defined and cannot be used in an 'is' expression");

  /**
   * 10 Generics: However, a type parameter is considered to be a malformed type
   * when referenced by a static member.
   *
   * 15.1 Static Types: Any use of a malformed type gives rise to a static
   * warning. A malformed type is then interpreted as dynamic by the static type
   * checker and the runtime.
   */
  static const StaticWarningCode TYPE_PARAMETER_REFERENCED_BY_STATIC =
      const StaticWarningCode('TYPE_PARAMETER_REFERENCED_BY_STATIC',
          "Static members cannot reference type parameters of the class");

  /**
   * 12.16.3 Static Invocation: A static method invocation <i>i</i> has the form
   * <i>C.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>:
   * a<sub>n+1</sub>, &hellip; x<sub>n+k</sub>: a<sub>n+k</sub>)</i>. It is a
   * static warning if <i>C</i> does not denote a class in the current scope.
   *
   * Parameters:
   * 0: the name of the undefined class
   */
  static const StaticWarningCode UNDEFINED_CLASS =
      const StaticWarningCode('UNDEFINED_CLASS', "Undefined class '{0}'");

  /**
   * Same as [UNDEFINED_CLASS], but to catch using "boolean" instead of "bool".
   */
  static const StaticWarningCode UNDEFINED_CLASS_BOOLEAN =
      const StaticWarningCode('UNDEFINED_CLASS_BOOLEAN',
          "Undefined class 'boolean'; did you mean 'bool'?");

  /**
   * 12.17 Getter Invocation: It is a static warning if there is no class
   * <i>C</i> in the enclosing lexical scope of <i>i</i>, or if <i>C</i> does
   * not declare, implicitly or explicitly, a getter named <i>m</i>.
   *
   * Parameters:
   * 0: the name of the getter
   * 1: the name of the enclosing type where the getter is being looked for
   */
  static const StaticWarningCode UNDEFINED_GETTER =
      shared_messages.UNDEFINED_GETTER_STATIC_WARNING;

  /**
   * 12.30 Identifier Reference: It is as static warning if an identifier
   * expression of the form <i>id</i> occurs inside a top level or static
   * function (be it function, method, getter, or setter) or variable
   * initializer and there is no declaration <i>d</i> with name <i>id</i> in the
   * lexical scope enclosing the expression.
   *
   * Parameters:
   * 0: the name of the identifier
   */
  static const StaticWarningCode UNDEFINED_IDENTIFIER =
      const StaticWarningCode('UNDEFINED_IDENTIFIER', "Undefined name '{0}'");

  /**
   * If the identifier is 'await', be helpful about it.
   */
  static const StaticWarningCode UNDEFINED_IDENTIFIER_AWAIT =
      const StaticWarningCode('UNDEFINED_IDENTIFIER_AWAIT',
          "Undefined name 'await'; did you mean to add the 'async' marker to '{0}'?");

  /**
   * 12.14.2 Binding Actuals to Formals: Furthermore, each <i>q<sub>i</sub></i>,
   * <i>1<=i<=l</i>, must have a corresponding named parameter in the set
   * {<i>p<sub>n+1</sub></i> &hellip; <i>p<sub>n+k</sub></i>} or a static
   * warning occurs.
   *
   * Parameters:
   * 0: the name of the requested named parameter
   */
  static const StaticWarningCode UNDEFINED_NAMED_PARAMETER =
      const StaticWarningCode('UNDEFINED_NAMED_PARAMETER',
          "The named parameter '{0}' is not defined");

  /**
   * 12.18 Assignment: It is as static warning if an assignment of the form
   * <i>v = e</i> occurs inside a top level or static function (be it function,
   * method, getter, or setter) or variable initializer and there is no
   * declaration <i>d</i> with name <i>v=</i> in the lexical scope enclosing the
   * assignment.
   *
   * 12.18 Assignment: It is a static warning if there is no class <i>C</i> in
   * the enclosing lexical scope of the assignment, or if <i>C</i> does not
   * declare, implicitly or explicitly, a setter <i>v=</i>.
   *
   * Parameters:
   * 0: the name of the getter
   * 1: the name of the enclosing type where the setter is being looked for
   */
  static const StaticWarningCode UNDEFINED_SETTER =
      shared_messages.UNDEFINED_SETTER_STATIC_WARNING;

  /**
   * 12.16.3 Static Invocation: It is a static warning if <i>C</i> does not
   * declare a static method or getter <i>m</i>.
   *
   * Parameters:
   * 0: the name of the method
   * 1: the name of the enclosing type where the method is being looked for
   */
  static const StaticWarningCode UNDEFINED_STATIC_METHOD_OR_GETTER =
      const StaticWarningCode('UNDEFINED_STATIC_METHOD_OR_GETTER',
          "The static method, getter or setter '{0}' is not defined for the class '{1}'");

  /**
   * 12.17 Getter Invocation: It is a static warning if there is no class
   * <i>C</i> in the enclosing lexical scope of <i>i</i>, or if <i>C</i> does
   * not declare, implicitly or explicitly, a getter named <i>m</i>.
   *
   * Parameters:
   * 0: the name of the getter
   * 1: the name of the enclosing type where the getter is being looked for
   */
  static const StaticWarningCode UNDEFINED_SUPER_GETTER =
      shared_messages.UNDEFINED_SUPER_GETTER_STATIC_WARNING;

  /**
   * 12.18 Assignment: It is as static warning if an assignment of the form
   * <i>v = e</i> occurs inside a top level or static function (be it function,
   * method, getter, or setter) or variable initializer and there is no
   * declaration <i>d</i> with name <i>v=</i> in the lexical scope enclosing the
   * assignment.
   *
   * 12.18 Assignment: It is a static warning if there is no class <i>C</i> in
   * the enclosing lexical scope of the assignment, or if <i>C</i> does not
   * declare, implicitly or explicitly, a setter <i>v=</i>.
   *
   * Parameters:
   * 0: the name of the getter
   * 1: the name of the enclosing type where the setter is being looked for
   */
  static const StaticWarningCode UNDEFINED_SUPER_SETTER =
      shared_messages.UNDEFINED_SUPER_SETTER_STATIC_WARNING;

  /**
   * 7.2 Getters: It is a static warning if the return type of a getter is void.
   */
  static const StaticWarningCode VOID_RETURN_FOR_GETTER =
      const StaticWarningCode('VOID_RETURN_FOR_GETTER',
          "The return type of the getter must not be 'void'", null, false);

  /**
   * A flag indicating whether this warning is an error when running with strong
   * mode enabled.
   */
  final bool isStrongModeError;

  /**
   * Initialize a newly created error code to have the given [name]. The message
   * associated with the error will be created from the given [message]
   * template. The correction associated with the error will be created from the
   * given [correction] template.
   */
  const StaticWarningCode(String name, String message,
      [String correction, this.isStrongModeError = true])
      : super(name, message, correction);

  @override
  ErrorSeverity get errorSeverity => ErrorType.STATIC_WARNING.severity;

  @override
  ErrorType get type => ErrorType.STATIC_WARNING;
}

/**
 * This class has Strong Mode specific error codes.
 *
 * These error codes tend to use the same message across different severity
 * levels, so they are grouped for clarity.
 *
 * All of these error codes also use the "STRONG_MODE_" prefix in their name.
 */
class StrongModeCode extends ErrorCode {
  static const String _implicitCastMessage =
      'Unsound implicit cast from {0} to {1}';

  static const String _unsafeBlockClosureInferenceMessage =
      'Unsafe use of block closure in a type-inferred variable outside a '
      'function body.  Workaround: add a type annotation for `{0}`.  See '
      'dartbug.com/26947';

  static const String _typeCheckMessage =
      'Type check failed: {0} is not of type {1}';

  static const String _invalidOverrideMessage =
      'The type of {0}.{1} ({2}) is not a '
      'subtype of {3}.{1} ({4}).';

  /**
   * This is appended to the end of an error message about implicit dynamic.
   *
   * The idea is to make sure the user is aware that this error message is the
   * result of turning on a particular option, and they are free to turn it
   * back off.
   */
  static const String _implicitDynamicTip =
      ". Either add an explicit type like 'dynamic'"
      ", or enable implicit-dynamic in your Analyzer options.";

  static const String _inferredTypeMessage = '{0} has inferred type {1}';

  static const StrongModeCode DOWN_CAST_COMPOSITE = const StrongModeCode(
      ErrorType.STATIC_WARNING, 'DOWN_CAST_COMPOSITE', _implicitCastMessage);

  static const StrongModeCode DOWN_CAST_IMPLICIT = const StrongModeCode(
      ErrorType.HINT, 'DOWN_CAST_IMPLICIT', _implicitCastMessage);

  static const StrongModeCode DYNAMIC_CAST = const StrongModeCode(
      ErrorType.HINT, 'DYNAMIC_CAST', _implicitCastMessage);

  static const StrongModeCode ASSIGNMENT_CAST = const StrongModeCode(
      ErrorType.HINT, 'ASSIGNMENT_CAST', _implicitCastMessage);

  static const StrongModeCode INVALID_PARAMETER_DECLARATION =
      const StrongModeCode(ErrorType.COMPILE_TIME_ERROR,
          'INVALID_PARAMETER_DECLARATION', _typeCheckMessage);

  static const StrongModeCode INFERRED_TYPE = const StrongModeCode(
      ErrorType.HINT, 'INFERRED_TYPE', _inferredTypeMessage);

  static const StrongModeCode INFERRED_TYPE_LITERAL = const StrongModeCode(
      ErrorType.HINT, 'INFERRED_TYPE_LITERAL', _inferredTypeMessage);

  static const StrongModeCode INFERRED_TYPE_ALLOCATION = const StrongModeCode(
      ErrorType.HINT, 'INFERRED_TYPE_ALLOCATION', _inferredTypeMessage);

  static const StrongModeCode INFERRED_TYPE_CLOSURE = const StrongModeCode(
      ErrorType.HINT, 'INFERRED_TYPE_CLOSURE', _inferredTypeMessage);

  static const StrongModeCode STATIC_TYPE_ERROR = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'STATIC_TYPE_ERROR',
      'Type check failed: {0} ({1}) is not of type {2}');

  static const StrongModeCode INVALID_SUPER_INVOCATION = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'INVALID_SUPER_INVOCATION',
      "super call must be last in an initializer "
      "list (see https://goo.gl/EY6hDP): {0}");

  static const StrongModeCode NON_GROUND_TYPE_CHECK_INFO = const StrongModeCode(
      ErrorType.HINT,
      'NON_GROUND_TYPE_CHECK_INFO',
      "Runtime check on non-ground type {0} may throw StrongModeError");

  static const StrongModeCode DYNAMIC_INVOKE = const StrongModeCode(
      ErrorType.HINT, 'DYNAMIC_INVOKE', '{0} requires a dynamic invoke');

  static const StrongModeCode INVALID_METHOD_OVERRIDE = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'INVALID_METHOD_OVERRIDE',
      'Invalid override. $_invalidOverrideMessage');

  static const StrongModeCode INVALID_METHOD_OVERRIDE_FROM_BASE =
      const StrongModeCode(
          ErrorType.COMPILE_TIME_ERROR,
          'INVALID_METHOD_OVERRIDE_FROM_BASE',
          'Base class introduces an invalid override. '
          '$_invalidOverrideMessage');

  static const StrongModeCode INVALID_METHOD_OVERRIDE_FROM_MIXIN =
      const StrongModeCode(
          ErrorType.COMPILE_TIME_ERROR,
          'INVALID_METHOD_OVERRIDE_FROM_MIXIN',
          'Mixin introduces an invalid override. $_invalidOverrideMessage');

  static const StrongModeCode INVALID_FIELD_OVERRIDE = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'INVALID_FIELD_OVERRIDE',
      'Field declaration {3}.{1} cannot be '
      'overridden in {0}.');

  static const StrongModeCode IMPLICIT_DYNAMIC_PARAMETER = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'IMPLICIT_DYNAMIC_PARAMETER',
      "Missing parameter type for '{0}'$_implicitDynamicTip");

  static const StrongModeCode IMPLICIT_DYNAMIC_RETURN = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'IMPLICIT_DYNAMIC_RETURN',
      "Missing return type for '{0}'$_implicitDynamicTip");

  static const StrongModeCode IMPLICIT_DYNAMIC_VARIABLE = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'IMPLICIT_DYNAMIC_VARIABLE',
      "Missing variable type for '{0}'$_implicitDynamicTip");

  static const StrongModeCode IMPLICIT_DYNAMIC_FIELD = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'IMPLICIT_DYNAMIC_FIELD',
      "Missing field type for '{0}'$_implicitDynamicTip");

  static const StrongModeCode IMPLICIT_DYNAMIC_TYPE = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'IMPLICIT_DYNAMIC_TYPE',
      "Missing type arguments for generic type '{0}'"
      "$_implicitDynamicTip");

  static const StrongModeCode IMPLICIT_DYNAMIC_LIST_LITERAL =
      const StrongModeCode(
          ErrorType.COMPILE_TIME_ERROR,
          'IMPLICIT_DYNAMIC_LIST_LITERAL',
          "Missing type argument for list literal$_implicitDynamicTip");

  static const StrongModeCode IMPLICIT_DYNAMIC_MAP_LITERAL =
      const StrongModeCode(
          ErrorType.COMPILE_TIME_ERROR,
          'IMPLICIT_DYNAMIC_MAP_LITERAL',
          'Missing type arguments for map literal$_implicitDynamicTip');

  static const StrongModeCode IMPLICIT_DYNAMIC_FUNCTION = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'IMPLICIT_DYNAMIC_FUNCTION',
      "Missing type arguments for generic function '{0}<{1}>'"
      "$_implicitDynamicTip");

  static const StrongModeCode IMPLICIT_DYNAMIC_METHOD = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'IMPLICIT_DYNAMIC_METHOD',
      "Missing type arguments for generic method '{0}<{1}>'"
      "$_implicitDynamicTip");

  static const StrongModeCode IMPLICIT_DYNAMIC_INVOKE = const StrongModeCode(
      ErrorType.COMPILE_TIME_ERROR,
      'IMPLICIT_DYNAMIC_INVOKE',
      "Missing type arguments for calling generic function type '{0}'"
      "$_implicitDynamicTip");

  static const StrongModeCode UNSAFE_BLOCK_CLOSURE_INFERENCE =
      const StrongModeCode(
          ErrorType.STATIC_WARNING,
          'UNSAFE_BLOCK_CLOSURE_INFERENCE',
          _unsafeBlockClosureInferenceMessage);

  @override
  final ErrorType type;

  /**
   * Initialize a newly created error code to have the given [type] and [name].
   *
   * The message associated with the error will be created from the given
   * [message] template. The correction associated with the error will be
   * created from the optional [correction] template.
   */
  const StrongModeCode(ErrorType type, String name, String message,
      [String correction])
      : type = type,
        super('STRONG_MODE_$name', message, correction);

  @override
  ErrorSeverity get errorSeverity => type.severity;
}

/**
 * The error code indicating a marker in code for work that needs to be finished
 * or revisited.
 */
class TodoCode extends ErrorCode {
  /**
   * The single enum of TodoCode.
   */
  static const TodoCode TODO = const TodoCode('TODO');

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
  static RegExp TODO_REGEX =
      new RegExp("([\\s/\\*])((TODO[^\\w\\d][^\\r\\n]*)|(TODO:?\$))");

  /**
   * Initialize a newly created error code to have the given [name].
   */
  const TodoCode(String name) : super(name, "{0}");

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.INFO;

  @override
  ErrorType get type => ErrorType.TODO;
}
