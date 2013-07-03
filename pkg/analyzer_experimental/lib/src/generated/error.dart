// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.
library engine.error;
import 'java_core.dart';
import 'source.dart';
import 'ast.dart' show ASTNode;
import 'scanner.dart' show Token;
/**
 * Instances of the enumeration `ErrorSeverity` represent the severity of an [ErrorCode]
 * .
 *
 * @coverage dart.engine.error
 */
class ErrorSeverity implements Comparable<ErrorSeverity> {

  /**
   * The severity representing a non-error. This is never used for any error code, but is useful for
   * clients.
   */
  static final ErrorSeverity NONE = new ErrorSeverity('NONE', 0, " ", "none");

  /**
   * The severity representing a suggestion. Suggestions are not specified in the Dart language
   * specification, but provide information about best practices.
   */
  static final ErrorSeverity SUGGESTION = new ErrorSeverity('SUGGESTION', 1, "S", "suggestion");

  /**
   * The severity representing a warning. Warnings can become errors if the `-Werror` command
   * line flag is specified.
   */
  static final ErrorSeverity WARNING = new ErrorSeverity('WARNING', 2, "W", "warning");

  /**
   * The severity representing an error.
   */
  static final ErrorSeverity ERROR = new ErrorSeverity('ERROR', 3, "E", "error");
  static final List<ErrorSeverity> values = [NONE, SUGGESTION, WARNING, ERROR];

  /// The name of this enum constant, as declared in the enum declaration.
  final String name;

  /// The position in the enum declaration.
  final int ordinal;

  /**
   * The name of the severity used when producing machine output.
   */
  String _machineCode;

  /**
   * The name of the severity used when producing readable output.
   */
  String _displayName;

  /**
   * Initialize a newly created severity with the given names.
   *
   * @param machineCode the name of the severity used when producing machine output
   * @param displayName the name of the severity used when producing readable output
   */
  ErrorSeverity(this.name, this.ordinal, String machineCode, String displayName) {
    this._machineCode = machineCode;
    this._displayName = displayName;
  }

  /**
   * Return the name of the severity used when producing readable output.
   *
   * @return the name of the severity used when producing readable output
   */
  String get displayName => _displayName;

  /**
   * Return the name of the severity used when producing machine output.
   *
   * @return the name of the severity used when producing machine output
   */
  String get machineCode => _machineCode;

  /**
   * Return the severity constant that represents the greatest severity.
   *
   * @param severity the severity being compared against
   * @return the most sever of this or the given severity
   */
  ErrorSeverity max(ErrorSeverity severity) => this.ordinal >= severity.ordinal ? this : severity;
  int compareTo(ErrorSeverity other) => ordinal - other.ordinal;
  int get hashCode => ordinal;
  String toString() => name;
}
/**
 * Instances of the class `AnalysisErrorWithProperties`
 */
class AnalysisErrorWithProperties extends AnalysisError {

  /**
   * The properties associated with this error.
   */
  Map<ErrorProperty, Object> _propertyMap = new Map<ErrorProperty, Object>();

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
 * Instances of the class `ErrorReporter` wrap an error listener with utility methods used to
 * create the errors being reported.
 *
 * @coverage dart.engine.error
 */
class ErrorReporter {

  /**
   * The error listener to which errors will be reported.
   */
  AnalysisErrorListener _errorListener;

  /**
   * The default source to be used when reporting errors.
   */
  Source _defaultSource;

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
  ErrorReporter(AnalysisErrorListener errorListener, Source defaultSource) {
    if (errorListener == null) {
      throw new IllegalArgumentException("An error listener must be provided");
    } else if (defaultSource == null) {
      throw new IllegalArgumentException("A default source must be provided");
    }
    this._errorListener = errorListener;
    this._defaultSource = defaultSource;
    this._source = defaultSource;
  }

  /**
   * Creates an error with properties with the given error code and arguments.
   *
   * @param errorCode the error code of the error to be reported
   * @param node the node specifying the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  AnalysisErrorWithProperties newErrorWithProperties(ErrorCode errorCode, ASTNode node, List<Object> arguments) => new AnalysisErrorWithProperties.con2(_source, node.offset, node.length, errorCode, arguments);

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
   * @param node the node specifying the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportError2(ErrorCode errorCode, ASTNode node, List<Object> arguments) {
    _errorListener.onError(new AnalysisError.con2(_source, node.offset, node.length, errorCode, arguments));
  }

  /**
   * Report an error with the given error code and arguments.
   *
   * @param errorCode the error code of the error to be reported
   * @param offset the offset of the location of the error
   * @param length the length of the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportError3(ErrorCode errorCode, int offset, int length, List<Object> arguments) {
    _errorListener.onError(new AnalysisError.con2(_source, offset, length, errorCode, arguments));
  }

  /**
   * Report an error with the given error code and arguments.
   *
   * @param errorCode the error code of the error to be reported
   * @param token the token specifying the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportError4(ErrorCode errorCode, Token token, List<Object> arguments) {
    _errorListener.onError(new AnalysisError.con2(_source, token.offset, token.length, errorCode, arguments));
  }

  /**
   * Set the source to be used when reporting errors. Setting the source to `null` will cause
   * the default source to be used.
   *
   * @param source the source to be used when reporting errors
   */
  void set source(Source source2) {
    this._source = source2 == null ? _defaultSource : source2;
  }
}
/**
 * Instances of the class `AnalysisError` represent an error discovered during the analysis of
 * some Dart code.
 *
 * @see AnalysisErrorListener
 * @coverage dart.engine.error
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
  ErrorCode _errorCode;

  /**
   * The localized error message.
   */
  String _message;

  /**
   * The source in which the error occurred, or `null` if unknown.
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
   *
   * @param source the source for which the exception occurred
   * @param errorCode the error code to be associated with this error
   * @param arguments the arguments used to build the error message
   */
  AnalysisError.con1(Source source, ErrorCode errorCode, List<Object> arguments) {
    this._source = source;
    this._errorCode = errorCode;
    this._message = JavaString.format(errorCode.message, arguments);
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
  AnalysisError.con2(Source source, int offset, int length, ErrorCode errorCode, List<Object> arguments) {
    this._source = source;
    this._offset = offset;
    this._length = length;
    this._errorCode = errorCode;
    this._message = JavaString.format(errorCode.message, arguments);
  }

  /**
   * Return the error code associated with the error.
   *
   * @return the error code associated with the error
   */
  ErrorCode get errorCode => _errorCode;

  /**
   * Return the number of characters from the offset to the end of the source which encompasses the
   * compilation error.
   *
   * @return the length of the error location
   */
  int get length => _length;

  /**
   * Return the localized error message.
   *
   * @return the localized error message
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

  /**
   * Return the source in which the error occurred, or `null` if unknown.
   *
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
   *
   * @param source the source in which the error occurred
   */
  void set source(Source source2) {
    this._source = source2;
  }
  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    builder.append((_source != null) ? _source.fullName : "<unknown source>");
    builder.append("(");
    builder.append(_offset);
    builder.append("..");
    builder.append(_offset + _length - 1);
    builder.append("): ");
    builder.append(_message);
    return builder.toString();
  }
}
/**
 * The enumeration `ErrorProperty` defines the properties that can be associated with an
 * [AnalysisError].
 */
class ErrorProperty implements Comparable<ErrorProperty> {

  /**
   * A property whose value is an array of [ExecutableElement] that should
   * be but are not implemented by a concrete class.
   */
  static final ErrorProperty UNIMPLEMENTED_METHODS = new ErrorProperty('UNIMPLEMENTED_METHODS', 0);
  static final List<ErrorProperty> values = [UNIMPLEMENTED_METHODS];

  /// The name of this enum constant, as declared in the enum declaration.
  final String name;

  /// The position in the enum declaration.
  final int ordinal;
  ErrorProperty(this.name, this.ordinal);
  int compareTo(ErrorProperty other) => ordinal - other.ordinal;
  int get hashCode => ordinal;
  String toString() => name;
}
/**
 * The enumeration `HintCode` defines the hints and coding recommendations for best practices
 * which are not mentioned in the Dart Language Specification.
 */
class HintCode implements Comparable<HintCode>, ErrorCode {

  /**
   * Dead code is code that is never reached, this can happen for instance if a statement follows a
   * return statement.
   */
  static final HintCode DEAD_CODE = new HintCode('DEAD_CODE', 0, "Dead code");

  /**
   * Dead code is code that is never reached. This case covers cases where the user has catch
   * clauses after `catch (e)` or `on Object catch (e)`.
   */
  static final HintCode DEAD_CODE_CATCH_FOLLOWING_CATCH = new HintCode('DEAD_CODE_CATCH_FOLLOWING_CATCH', 1, "Dead code, catch clauses after a 'catch (e)' or an 'on Object catch (e)' are never reached");

  /**
   * Dead code is code that is never reached. This case covers cases where the user has an on-catch
   * clause such as `on A catch (e)`, where a supertype of `A` was already caught.
   *
   * @param subtypeName name of the subtype
   * @param supertypeName name of the supertype
   */
  static final HintCode DEAD_CODE_ON_CATCH_SUBTYPE = new HintCode('DEAD_CODE_ON_CATCH_SUBTYPE', 2, "Dead code, this on-catch block will never be executed since '%s' is a subtype of '%s'");
  static final List<HintCode> values = [DEAD_CODE, DEAD_CODE_CATCH_FOLLOWING_CATCH, DEAD_CODE_ON_CATCH_SUBTYPE];

  /// The name of this enum constant, as declared in the enum declaration.
  final String name;

  /// The position in the enum declaration.
  final int ordinal;

  /**
   * The message template used to create the message to be displayed for this error.
   */
  String _message;

  /**
   * Initialize a newly created error code to have the given message.
   *
   * @param message the message template used to create the message to be displayed for the error
   */
  HintCode(this.name, this.ordinal, String message) {
    this._message = message;
  }
  ErrorSeverity get errorSeverity => ErrorType.HINT.severity;
  String get message => _message;
  ErrorType get type => ErrorType.HINT;
  int compareTo(HintCode other) => ordinal - other.ordinal;
  int get hashCode => ordinal;
  String toString() => name;
}
/**
 * The interface `ErrorCode` defines the behavior common to objects representing error codes
 * associated with [AnalysisError].
 *
 * @coverage dart.engine.error
 */
abstract class ErrorCode {

  /**
   * Return the severity of this error.
   *
   * @return the severity of this error
   */
  ErrorSeverity get errorSeverity;

  /**
   * Return the message template used to create the message to be displayed for this error.
   *
   * @return the message template used to create the message to be displayed for this error
   */
  String get message;

  /**
   * Return the type of the error.
   *
   * @return the type of the error
   */
  ErrorType get type;
}
/**
 * Instances of the enumeration `ErrorType` represent the type of an [ErrorCode].
 *
 * @coverage dart.engine.error
 */
class ErrorType implements Comparable<ErrorType> {

  /**
   * Extra analysis run over the code to follow best practices, which are not in the Dart Language
   * Specification.
   */
  static final ErrorType HINT = new ErrorType('HINT', 0, ErrorSeverity.SUGGESTION);

  /**
   * Compile-time errors are errors that preclude execution. A compile time error must be reported
   * by a Dart compiler before the erroneous code is executed.
   */
  static final ErrorType COMPILE_TIME_ERROR = new ErrorType('COMPILE_TIME_ERROR', 1, ErrorSeverity.ERROR);

  /**
   * Suggestions made in situations where the user has deviated from recommended pub programming
   * practices.
   */
  static final ErrorType PUB_SUGGESTION = new ErrorType('PUB_SUGGESTION', 2, ErrorSeverity.SUGGESTION);

  /**
   * Static warnings are those warnings reported by the static checker. They have no effect on
   * execution. Static warnings must be provided by Dart compilers used during development.
   */
  static final ErrorType STATIC_WARNING = new ErrorType('STATIC_WARNING', 3, ErrorSeverity.WARNING);

  /**
   * Many, but not all, static warnings relate to types, in which case they are known as static type
   * warnings.
   */
  static final ErrorType STATIC_TYPE_WARNING = new ErrorType('STATIC_TYPE_WARNING', 4, ErrorSeverity.WARNING);

  /**
   * Syntactic errors are errors produced as a result of input that does not conform to the grammar.
   */
  static final ErrorType SYNTACTIC_ERROR = new ErrorType('SYNTACTIC_ERROR', 5, ErrorSeverity.ERROR);
  static final List<ErrorType> values = [HINT, COMPILE_TIME_ERROR, PUB_SUGGESTION, STATIC_WARNING, STATIC_TYPE_WARNING, SYNTACTIC_ERROR];

  /// The name of this enum constant, as declared in the enum declaration.
  final String name;

  /// The position in the enum declaration.
  final int ordinal;

  /**
   * The severity of this type of error.
   */
  ErrorSeverity _severity;

  /**
   * Initialize a newly created error type to have the given severity.
   *
   * @param severity the severity of this type of error
   */
  ErrorType(this.name, this.ordinal, ErrorSeverity severity) {
    this._severity = severity;
  }

  /**
   * Return the severity of this type of error.
   *
   * @return the severity of this type of error
   */
  ErrorSeverity get severity => _severity;
  int compareTo(ErrorType other) => ordinal - other.ordinal;
  int get hashCode => ordinal;
  String toString() => name;
}
/**
 * The enumeration `CompileTimeErrorCode` defines the error codes used for compile time
 * errors. The convention for this class is for the name of the error code to indicate the problem
 * that caused the error to be generated and for the error message to explain what is wrong and,
 * when appropriate, how the problem can be corrected.
 *
 * @coverage dart.engine.error
 */
class CompileTimeErrorCode implements Comparable<CompileTimeErrorCode>, ErrorCode {

  /**
   * 14.2 Exports: It is a compile-time error if a name <i>N</i> is re-exported by a library
   * <i>L</i> and <i>N</i> is introduced into the export namespace of <i>L</i> by more than one
   * export.
   *
   * @param ambiguousElementName the name of the ambiguous element
   * @param firstLibraryName the name of the first library that the type is found
   * @param secondLibraryName the name of the second library that the type is found
   */
  static final CompileTimeErrorCode AMBIGUOUS_EXPORT = new CompileTimeErrorCode('AMBIGUOUS_EXPORT', 0, "The element '%s' is defined in the libraries '%s' and '%s'");

  /**
   * 14.1 Imports: If a name <i>N</i> is referenced by a library <i>L</i> and <i>N</i> is introduced
   * into the top level scope <i>L</i> by more than one import then:
   * <ol>
   * * It is a static warning if <i>N</i> is used as a type annotation.
   * * In checked mode, it is a dynamic error if <i>N</i> is used as a type annotation and
   * referenced during a subtype test.
   * * Otherwise, it is a compile-time error.
   * </ol>
   *
   * @param ambiguousElementName the name of the ambiguous element
   * @param firstLibraryName the name of the first library that the type is found
   * @param secondLibraryName the name of the second library that the type is found
   */
  static final CompileTimeErrorCode AMBIGUOUS_IMPORT = new CompileTimeErrorCode('AMBIGUOUS_IMPORT', 1, "The element '%s' is defined in the libraries '%s' and '%s'");

  /**
   * 12.33 Argument Definition Test: It is a compile time error if <i>v</i> does not denote a formal
   * parameter.
   *
   * @param the name of the identifier in the argument definition test that is not a parameter
   */
  static final CompileTimeErrorCode ARGUMENT_DEFINITION_TEST_NON_PARAMETER = new CompileTimeErrorCode('ARGUMENT_DEFINITION_TEST_NON_PARAMETER', 2, "'%s' is not a parameter");

  /**
   * 12.30 Identifier Reference: It is a compile-time error to use a built-in identifier other than
   * dynamic as a type annotation.
   */
  static final CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_TYPE = new CompileTimeErrorCode('BUILT_IN_IDENTIFIER_AS_TYPE', 3, "The built-in identifier '%s' cannot be as a type");

  /**
   * 12.30 Identifier Reference: It is a compile-time error if a built-in identifier is used as the
   * declared name of a class, type parameter or type alias.
   */
  static final CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_TYPE_NAME = new CompileTimeErrorCode('BUILT_IN_IDENTIFIER_AS_TYPE_NAME', 4, "The built-in identifier '%s' cannot be used as a type name");

  /**
   * 12.30 Identifier Reference: It is a compile-time error if a built-in identifier is used as the
   * declared name of a class, type parameter or type alias.
   */
  static final CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME = new CompileTimeErrorCode('BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME', 5, "The built-in identifier '%s' cannot be used as a type alias name");

  /**
   * 12.30 Identifier Reference: It is a compile-time error if a built-in identifier is used as the
   * declared name of a class, type parameter or type alias.
   */
  static final CompileTimeErrorCode BUILT_IN_IDENTIFIER_AS_TYPE_VARIABLE_NAME = new CompileTimeErrorCode('BUILT_IN_IDENTIFIER_AS_TYPE_VARIABLE_NAME', 6, "The built-in identifier '%s' cannot be used as a type variable name");

  /**
   * 13.9 Switch: It is a compile-time error if the class <i>C</i> implements the operator
   * <i>==</i>.
   */
  static final CompileTimeErrorCode CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS = new CompileTimeErrorCode('CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS', 7, "The switch case expression type '%s' cannot override the == operator");

  /**
   * 12.1 Constants: It is a compile-time error if evaluation of a compile-time constant would raise
   * an exception.
   */
  static final CompileTimeErrorCode COMPILE_TIME_CONSTANT_RAISES_EXCEPTION = new CompileTimeErrorCode('COMPILE_TIME_CONSTANT_RAISES_EXCEPTION', 8, "");

  /**
   * 7.2 Getters: It is a compile-time error if a class has both a getter and a method with the same
   * name. This restriction holds regardless of whether the getter is defined explicitly or
   * implicitly, or whether the getter or the method are inherited or not.
   */
  static final CompileTimeErrorCode CONFLICTING_GETTER_AND_METHOD = new CompileTimeErrorCode('CONFLICTING_GETTER_AND_METHOD', 9, "Class '%s' cannot have both getter '%s.%s' and method with the same name");

  /**
   * 7.2 Getters: It is a compile-time error if a class has both a getter and a method with the same
   * name. This restriction holds regardless of whether the getter is defined explicitly or
   * implicitly, or whether the getter or the method are inherited or not.
   */
  static final CompileTimeErrorCode CONFLICTING_METHOD_AND_GETTER = new CompileTimeErrorCode('CONFLICTING_METHOD_AND_GETTER', 10, "Class '%s' cannot have both method '%s.%s' and getter with the same name");

  /**
   * 7.6 Constructors: A constructor name always begins with the name of its immediately enclosing
   * class, and may optionally be followed by a dot and an identifier <i>id</i>. It is a
   * compile-time error if <i>id</i> is the name of a member declared in the immediately enclosing
   * class.
   */
  static final CompileTimeErrorCode CONFLICTING_CONSTRUCTOR_NAME_AND_FIELD = new CompileTimeErrorCode('CONFLICTING_CONSTRUCTOR_NAME_AND_FIELD', 11, "'%s' cannot be used to name a constructor and a field in this class");

  /**
   * 7.6 Constructors: A constructor name always begins with the name of its immediately enclosing
   * class, and may optionally be followed by a dot and an identifier <i>id</i>. It is a
   * compile-time error if <i>id</i> is the name of a member declared in the immediately enclosing
   * class.
   */
  static final CompileTimeErrorCode CONFLICTING_CONSTRUCTOR_NAME_AND_METHOD = new CompileTimeErrorCode('CONFLICTING_CONSTRUCTOR_NAME_AND_METHOD', 12, "'%s' cannot be used to name a constructor and a method in this class");

  /**
   * 12.11.2 Const: It is a compile-time error if evaluation of a constant object results in an
   * uncaught exception being thrown.
   */
  static final CompileTimeErrorCode CONST_CONSTRUCTOR_THROWS_EXCEPTION = new CompileTimeErrorCode('CONST_CONSTRUCTOR_THROWS_EXCEPTION', 13, "'const' constructors cannot throw exceptions");

  /**
   * 7.6.3 Constant Constructors: It is a compile-time error if a constant constructor is declared
   * by a class that has a non-final instance variable.
   *
   * The above refers to both locally declared and inherited instance variables.
   */
  static final CompileTimeErrorCode CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD = new CompileTimeErrorCode('CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD', 14, "Cannot define the 'const' constructor for a class with non-final fields");

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
  static final CompileTimeErrorCode CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE = new CompileTimeErrorCode('CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE', 15, "The initializer type '%s' cannot be assigned to the field type '%s'");

  /**
   * 6.2 Formal Parameters: It is a compile-time error if a formal parameter is declared as a
   * constant variable.
   */
  static final CompileTimeErrorCode CONST_FORMAL_PARAMETER = new CompileTimeErrorCode('CONST_FORMAL_PARAMETER', 16, "Parameters cannot be 'const'");

  /**
   * 5 Variables: A constant variable must be initialized to a compile-time constant or a
   * compile-time error occurs.
   */
  static final CompileTimeErrorCode CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE = new CompileTimeErrorCode('CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE', 17, "'const' variables must be constant value");

  /**
   * 7.5 Instance Variables: It is a compile-time error if an instance variable is declared to be
   * constant.
   */
  static final CompileTimeErrorCode CONST_INSTANCE_FIELD = new CompileTimeErrorCode('CONST_INSTANCE_FIELD', 18, "Only static fields can be declared as 'const'");

  /**
   * 12.11.2 Const: An expression of one of the forms !e, e1 && e2 or e1 || e2, where e, e1 and e2
   * are constant expressions that evaluate to a boolean value.
   */
  static final CompileTimeErrorCode CONST_EVAL_TYPE_BOOL = new CompileTimeErrorCode('CONST_EVAL_TYPE_BOOL', 19, "An expression of type 'bool' was expected");

  /**
   * 12.11.2 Const: An expression of one of the forms e1 == e2 or e1 != e2 where e1 and e2 are
   * constant expressions that evaluate to a numeric, string or boolean value or to null.
   */
  static final CompileTimeErrorCode CONST_EVAL_TYPE_BOOL_NUM_STRING = new CompileTimeErrorCode('CONST_EVAL_TYPE_BOOL_NUM_STRING', 20, "An expression of type 'bool', 'num', 'String' or 'null' was expected");

  /**
   * 12.11.2 Const: An expression of one of the forms ~e, e1 ^ e2, e1 & e2, e1 | e2, e1 >> e2 or e1
   * << e2, where e, e1 and e2 are constant expressions that evaluate to an integer value or to
   * null.
   */
  static final CompileTimeErrorCode CONST_EVAL_TYPE_INT = new CompileTimeErrorCode('CONST_EVAL_TYPE_INT', 21, "An expression of type 'int' was expected");

  /**
   * 12.11.2 Const: An expression of one of the forms e, e1 + e2, e1 - e2, e1 * e2, e1 / e2, e1 ~/
   * e2, e1 > e2, e1 < e2, e1 >= e2, e1 <= e2 or e1 % e2, where e, e1 and e2 are constant
   * expressions that evaluate to a numeric value or to null..
   */
  static final CompileTimeErrorCode CONST_EVAL_TYPE_NUM = new CompileTimeErrorCode('CONST_EVAL_TYPE_NUM', 22, "An expression of type 'num' was expected");

  /**
   * 12.11.2 Const: It is a compile-time error if evaluation of a constant object results in an
   * uncaught exception being thrown.
   */
  static final CompileTimeErrorCode CONST_EVAL_THROWS_EXCEPTION = new CompileTimeErrorCode('CONST_EVAL_THROWS_EXCEPTION', 23, "Evaluation of this constant expression causes exception");

  /**
   * 12.11.2 Const: It is a compile-time error if evaluation of a constant object results in an
   * uncaught exception being thrown.
   */
  static final CompileTimeErrorCode CONST_EVAL_THROWS_IDBZE = new CompileTimeErrorCode('CONST_EVAL_THROWS_IDBZE', 24, "Evaluation of this constant expression throws IntegerDivisionByZeroException");

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
  static final CompileTimeErrorCode CONST_WITH_INVALID_TYPE_PARAMETERS = new CompileTimeErrorCode('CONST_WITH_INVALID_TYPE_PARAMETERS', 25, "The type '%s' is declared with %d type parameters, but %d type arguments were given");

  /**
   * 12.11.2 Const: If <i>e</i> is of the form <i>const T(a<sub>1</sub>, &hellip;, a<sub>n</sub>,
   * x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;, x<sub>n+k</sub>: a<sub>n+k</sub>)</i> it is a
   * compile-time error if the type <i>T</i> does not declare a constant constructor with the same
   * name as the declaration of <i>T</i>.
   */
  static final CompileTimeErrorCode CONST_WITH_NON_CONST = new CompileTimeErrorCode('CONST_WITH_NON_CONST', 26, "The constructor being called is not a 'const' constructor");

  /**
   * 12.11.2 Const: In all of the above cases, it is a compile-time error if <i>a<sub>i</sub>, 1
   * &lt;= i &lt;= n + k</i>, is not a compile-time constant expression.
   */
  static final CompileTimeErrorCode CONST_WITH_NON_CONSTANT_ARGUMENT = new CompileTimeErrorCode('CONST_WITH_NON_CONSTANT_ARGUMENT', 27, "Arguments of a constant creation must be constant expressions");

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
  static final CompileTimeErrorCode CONST_WITH_NON_TYPE = new CompileTimeErrorCode('CONST_WITH_NON_TYPE', 28, "The name '%s' is not a class");

  /**
   * 12.11.2 Const: It is a compile-time error if <i>T</i> includes any type parameters.
   */
  static final CompileTimeErrorCode CONST_WITH_TYPE_PARAMETERS = new CompileTimeErrorCode('CONST_WITH_TYPE_PARAMETERS', 29, "The constant creation cannot use a type parameter");

  /**
   * 12.11.2 Const: It is a compile-time error if <i>T.id</i> is not the name of a constant
   * constructor declared by the type <i>T</i>.
   *
   * @param typeName the name of the type
   * @param constructorName the name of the requested constant constructor
   */
  static final CompileTimeErrorCode CONST_WITH_UNDEFINED_CONSTRUCTOR = new CompileTimeErrorCode('CONST_WITH_UNDEFINED_CONSTRUCTOR', 30, "The class '%s' does not have a constant constructor '%s'");

  /**
   * 12.11.2 Const: It is a compile-time error if <i>T.id</i> is not the name of a constant
   * constructor declared by the type <i>T</i>.
   *
   * @param typeName the name of the type
   */
  static final CompileTimeErrorCode CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT = new CompileTimeErrorCode('CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT', 31, "The class '%s' does not have a default constant constructor");

  /**
   * 15.3.1 Typedef: It is a compile-time error if any default values are specified in the signature
   * of a function type alias.
   */
  static final CompileTimeErrorCode DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS = new CompileTimeErrorCode('DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS', 32, "Default values aren't allowed in typedefs");

  /**
   * 3.1 Scoping: It is a compile-time error if there is more than one entity with the same name
   * declared in the same scope.
   */
  static final CompileTimeErrorCode DUPLICATE_CONSTRUCTOR_DEFAULT = new CompileTimeErrorCode('DUPLICATE_CONSTRUCTOR_DEFAULT', 33, "The default constructor is already defined");

  /**
   * 3.1 Scoping: It is a compile-time error if there is more than one entity with the same name
   * declared in the same scope.
   *
   * @param duplicateName the name of the duplicate entity
   */
  static final CompileTimeErrorCode DUPLICATE_CONSTRUCTOR_NAME = new CompileTimeErrorCode('DUPLICATE_CONSTRUCTOR_NAME', 34, "The constructor with name '%s' is already defined");

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
  static final CompileTimeErrorCode DUPLICATE_DEFINITION = new CompileTimeErrorCode('DUPLICATE_DEFINITION', 35, "The name '%s' is already defined");

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
  static final CompileTimeErrorCode DUPLICATE_DEFINITION_INHERITANCE = new CompileTimeErrorCode('DUPLICATE_DEFINITION_INHERITANCE', 36, "The name '%s' is already defined in '%s'");

  /**
   * 12.14.2 Binding Actuals to Formals: It is a compile-time error if <i>q<sub>i</sub> =
   * q<sub>j</sub></i> for any <i>i != j</i> [where <i>q<sub>i</sub></i> is the label for a named
   * argument].
   */
  static final CompileTimeErrorCode DUPLICATE_NAMED_ARGUMENT = new CompileTimeErrorCode('DUPLICATE_NAMED_ARGUMENT', 37, "The argument for the named parameter '%s' was already specified");

  /**
   * SDK implementation libraries can be exported only by other SDK libraries.
   *
   * @param uri the uri pointing to a library
   */
  static final CompileTimeErrorCode EXPORT_INTERNAL_LIBRARY = new CompileTimeErrorCode('EXPORT_INTERNAL_LIBRARY', 38, "The library %s is internal and cannot be exported");

  /**
   * 14.2 Exports: It is a compile-time error if the compilation unit found at the specified URI is
   * not a library declaration.
   *
   * @param uri the uri pointing to a non-library declaration
   */
  static final CompileTimeErrorCode EXPORT_OF_NON_LIBRARY = new CompileTimeErrorCode('EXPORT_OF_NON_LIBRARY', 39, "The exported library '%s' must not have a part-of directive");

  /**
   * 7.9 Superclasses: It is a compile-time error if the extends clause of a class <i>C</i> includes
   * a type expression that does not denote a class available in the lexical scope of <i>C</i>.
   *
   * @param typeName the name of the superclass that was not found
   */
  static final CompileTimeErrorCode EXTENDS_NON_CLASS = new CompileTimeErrorCode('EXTENDS_NON_CLASS', 40, "Classes can only extend other classes");

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
  static final CompileTimeErrorCode EXTENDS_DISALLOWED_CLASS = new CompileTimeErrorCode('EXTENDS_DISALLOWED_CLASS', 41, "Classes cannot extend '%s'");

  /**
   * 12.14.2 Binding Actuals to Formals: It is a static warning if <i>m < h</i> or if <i>m > n</i>.
   *
   * 12.11.2 Const: It is a compile-time error if evaluation of a constant object results in an
   * uncaught exception being thrown.
   *
   * @param requiredCount the maximum number of positional arguments
   * @param argumentCount the actual number of positional arguments given
   */
  static final CompileTimeErrorCode EXTRA_POSITIONAL_ARGUMENTS = new CompileTimeErrorCode('EXTRA_POSITIONAL_ARGUMENTS', 42, "%d positional arguments expected, but %d found");

  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It is a compile time
   * error if more than one initializer corresponding to a given instance variable appears in
   * <i>k</i>'s list.
   */
  static final CompileTimeErrorCode FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS = new CompileTimeErrorCode('FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS', 43, "The field '%s' cannot be initialized twice in the same constructor");

  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It is a compile time
   * error if <i>k</i>'s initializer list contains an initializer for a final variable <i>f</i>
   * whose declaration includes an initialization expression.
   */
  static final CompileTimeErrorCode FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION = new CompileTimeErrorCode('FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION', 44, "Values cannot be set in the constructor if they are final, and have already been set");

  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It is a compile time
   * error if <i>k</i>'s initializer list contains an initializer for a variable that is initialized
   * by means of an initializing formal of <i>k</i>.
   */
  static final CompileTimeErrorCode FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER = new CompileTimeErrorCode('FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER', 45, "Fields cannot be initialized in both the parameter list and the initializers");

  /**
   * 5 Variables: It is a compile-time error if a final instance variable that has been initialized
   * at its point of declaration is also initialized in a constructor.
   *
   * @param name the name of the field in question
   */
  static final CompileTimeErrorCode FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR = new CompileTimeErrorCode('FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR', 46, "'%s' is final and was given a value when it was declared, so it cannot be set to a new value");

  /**
   * 5 Variables: It is a compile-time error if a final instance variable that has is initialized by
   * means of an initializing formal of a constructor is also initialized elsewhere in the same
   * constructor.
   *
   * @param name the name of the field in question
   */
  static final CompileTimeErrorCode FINAL_INITIALIZED_MULTIPLE_TIMES = new CompileTimeErrorCode('FINAL_INITIALIZED_MULTIPLE_TIMES', 47, "'%s' is a final field and so can only be set once");

  /**
   * 7.6.1 Generative Constructors: It is a compile-time error if an initializing formal is used by
   * a function other than a non-redirecting generative constructor.
   */
  static final CompileTimeErrorCode FIELD_INITIALIZER_FACTORY_CONSTRUCTOR = new CompileTimeErrorCode('FIELD_INITIALIZER_FACTORY_CONSTRUCTOR', 48, "Initializing formal fields cannot be used in factory constructors");

  /**
   * 7.6.1 Generative Constructors: It is a compile-time error if an initializing formal is used by
   * a function other than a non-redirecting generative constructor.
   */
  static final CompileTimeErrorCode FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR = new CompileTimeErrorCode('FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR', 49, "Initializing formal fields can only be used in constructors");

  /**
   * 7.6.1 Generative Constructors: A generative constructor may be redirecting, in which case its
   * only action is to invoke another generative constructor.
   *
   * 7.6.1 Generative Constructors: It is a compile-time error if an initializing formal is used by
   * a function other than a non-redirecting generative constructor.
   */
  static final CompileTimeErrorCode FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR = new CompileTimeErrorCode('FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR', 50, "The redirecting constructor cannot have a field initializer");

  /**
   * 7.2 Getters: It is a compile-time error if a class has both a getter and a method with the same
   * name.
   *
   * @param name the conflicting name of the getter and method
   */
  static final CompileTimeErrorCode GETTER_AND_METHOD_WITH_SAME_NAME = new CompileTimeErrorCode('GETTER_AND_METHOD_WITH_SAME_NAME', 51, "'%s' cannot be used to name a getter, there is already a method with the same name");

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
  static final CompileTimeErrorCode IMPLEMENTS_DISALLOWED_CLASS = new CompileTimeErrorCode('IMPLEMENTS_DISALLOWED_CLASS', 52, "Classes cannot implement '%s'");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the implements clause of a class includes
   * type dynamic.
   */
  static final CompileTimeErrorCode IMPLEMENTS_DYNAMIC = new CompileTimeErrorCode('IMPLEMENTS_DYNAMIC', 53, "Classes cannot implement 'dynamic'");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if the implements clause of a class <i>C</i>
   * includes a type expression that does not denote a class available in the lexical scope of
   * <i>C</i>.
   *
   * @param typeName the name of the interface that was not found
   */
  static final CompileTimeErrorCode IMPLEMENTS_NON_CLASS = new CompileTimeErrorCode('IMPLEMENTS_NON_CLASS', 54, "Classes can only implement other classes");

  /**
   * 7.10 Superinterfaces: It is a compile-time error if a type <i>T</i> appears more than once in
   * the implements clause of a class.
   *
   * @param className the name of the class that is implemented more than once
   */
  static final CompileTimeErrorCode IMPLEMENTS_REPEATED = new CompileTimeErrorCode('IMPLEMENTS_REPEATED', 55, "'%s' can only be implemented once");

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
  static final CompileTimeErrorCode IMPLICIT_THIS_REFERENCE_IN_INITIALIZER = new CompileTimeErrorCode('IMPLICIT_THIS_REFERENCE_IN_INITIALIZER', 56, "The 'this' expression cannot be implicitly used in initializers");

  /**
   * SDK implementation libraries can be imported only by other SDK libraries.
   *
   * @param uri the uri pointing to a library
   */
  static final CompileTimeErrorCode IMPORT_INTERNAL_LIBRARY = new CompileTimeErrorCode('IMPORT_INTERNAL_LIBRARY', 57, "The library %s is internal and cannot be imported");

  /**
   * 14.1 Imports: It is a compile-time error if the compilation unit found at the specified URI is
   * not a library declaration.
   *
   * @param uri the uri pointing to a non-library declaration
   */
  static final CompileTimeErrorCode IMPORT_OF_NON_LIBRARY = new CompileTimeErrorCode('IMPORT_OF_NON_LIBRARY', 58, "The imported library '%s' must not have a part-of directive");

  /**
   * 13.9 Switch: It is a compile-time error if values of the expressions <i>e<sub>k</sub></i> are
   * not instances of the same class <i>C</i>, for all <i>1 &lt;= k &lt;= n</i>.
   *
   * @param expressionSource the expression source code that is the unexpected type
   * @param expectedType the name of the expected type
   */
  static final CompileTimeErrorCode INCONSISTENT_CASE_EXPRESSION_TYPES = new CompileTimeErrorCode('INCONSISTENT_CASE_EXPRESSION_TYPES', 59, "Case expressions must have the same types, '%s' is not a %s'");

  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It is a compile-time
   * error if <i>k</i>'s initializer list contains an initializer for a variable that is not an
   * instance variable declared in the immediately surrounding class.
   *
   * @param id the name of the initializing formal that is not an instance variable in the
   *          immediately enclosing class
   * @see #INITIALIZING_FORMAL_FOR_NON_EXISTANT_FIELD
   */
  static final CompileTimeErrorCode INITIALIZER_FOR_NON_EXISTANT_FIELD = new CompileTimeErrorCode('INITIALIZER_FOR_NON_EXISTANT_FIELD', 60, "'%s' is not a variable in the enclosing class");

  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It is a compile-time
   * error if <i>k</i>'s initializer list contains an initializer for a variable that is not an
   * instance variable declared in the immediately surrounding class.
   *
   * @param id the name of the initializing formal that is a static variable in the immediately
   *          enclosing class
   * @see #INITIALIZING_FORMAL_FOR_STATIC_FIELD
   */
  static final CompileTimeErrorCode INITIALIZER_FOR_STATIC_FIELD = new CompileTimeErrorCode('INITIALIZER_FOR_STATIC_FIELD', 61, "'%s' is a static variable in the enclosing class, variables initialized in a constructor cannot be static");

  /**
   * 7.6.1 Generative Constructors: An initializing formal has the form <i>this.id</i>. It is a
   * compile-time error if <i>id</i> is not the name of an instance variable of the immediately
   * enclosing class.
   *
   * @param id the name of the initializing formal that is not an instance variable in the
   *          immediately enclosing class
   * @see #INITIALIZING_FORMAL_FOR_STATIC_FIELD
   * @see #INITIALIZER_FOR_NON_EXISTANT_FIELD
   */
  static final CompileTimeErrorCode INITIALIZING_FORMAL_FOR_NON_EXISTANT_FIELD = new CompileTimeErrorCode('INITIALIZING_FORMAL_FOR_NON_EXISTANT_FIELD', 62, "'%s' is not a variable in the enclosing class");

  /**
   * 7.6.1 Generative Constructors: An initializing formal has the form <i>this.id</i>. It is a
   * compile-time error if <i>id</i> is not the name of an instance variable of the immediately
   * enclosing class.
   *
   * @param id the name of the initializing formal that is a static variable in the immediately
   *          enclosing class
   * @see #INITIALIZER_FOR_STATIC_FIELD
   */
  static final CompileTimeErrorCode INITIALIZING_FORMAL_FOR_STATIC_FIELD = new CompileTimeErrorCode('INITIALIZING_FORMAL_FOR_STATIC_FIELD', 63, "'%s' is a static variable in the enclosing class, variables initialized in a constructor cannot be static");

  /**
   * 12.30 Identifier Reference: Otherwise, e is equivalent to the property extraction
   * <b>this</b>.<i>id</i>.
   */
  static final CompileTimeErrorCode INSTANCE_MEMBER_ACCESS_FROM_STATIC = new CompileTimeErrorCode('INSTANCE_MEMBER_ACCESS_FROM_STATIC', 64, "Instance member cannot be accessed from static method");

  /**
   * 11 Metadata: Metadata consists of a series of annotations, each of which begin with the
   * character @, followed by a constant expression that must be either a reference to a
   * compile-time constant variable, or a call to a constant constructor.
   */
  static final CompileTimeErrorCode INVALID_ANNOTATION = new CompileTimeErrorCode('INVALID_ANNOTATION', 65, "Annotation can be only constant variable or constant constructor invocation");

  /**
   * TODO(brianwilkerson) Remove this when we have decided on how to report errors in compile-time
   * constants. Until then, this acts as a placeholder for more informative errors.
   */
  static final CompileTimeErrorCode INVALID_CONSTANT = new CompileTimeErrorCode('INVALID_CONSTANT', 66, "");

  /**
   * 7.6 Constructors: It is a compile-time error if the name of a constructor is not a constructor
   * name.
   */
  static final CompileTimeErrorCode INVALID_CONSTRUCTOR_NAME = new CompileTimeErrorCode('INVALID_CONSTRUCTOR_NAME', 67, "Invalid constructor name");

  /**
   * 7.6.2 Factories: It is a compile-time error if <i>M</i> is not the name of the immediately
   * enclosing class.
   */
  static final CompileTimeErrorCode INVALID_FACTORY_NAME_NOT_A_CLASS = new CompileTimeErrorCode('INVALID_FACTORY_NAME_NOT_A_CLASS', 68, "The name of the immediately enclosing class expected");

  /**
   * 7.1 Instance Methods: It is a compile-time error if an instance method <i>m1</i> overrides an
   * instance member <i>m2</i> and <i>m1</i> does not declare all the named parameters declared by
   * <i>m2</i>.
   *
   * @param paramCount the number of named parameters in the overridden member
   * @param className the name of the class from the overridden method
   */
  static final CompileTimeErrorCode INVALID_OVERRIDE_NAMED = new CompileTimeErrorCode('INVALID_OVERRIDE_NAMED', 69, "Missing the named parameter '%s' to match the overridden method from '%s'");

  /**
   * 7.1 Instance Methods: It is a compile-time error if an instance method <i>m1</i> overrides an
   * instance member <i>m2</i> and <i>m1</i> has fewer optional positional parameters than
   * <i>m2</i>.
   *
   * @param paramCount the number of positional parameters in the overridden member
   * @param className the name of the class from the overridden method
   */
  static final CompileTimeErrorCode INVALID_OVERRIDE_POSITIONAL = new CompileTimeErrorCode('INVALID_OVERRIDE_POSITIONAL', 70, "Must have at least %d optional parameters to match the overridden method from '%s'");

  /**
   * 7.1 Instance Methods: It is a compile-time error if an instance method <i>m1</i> overrides an
   * instance member <i>m2</i> and <i>m1</i> has a different number of required parameters than
   * <i>m2</i>.
   *
   * @param paramCount the number of required parameters in the overridden member
   * @param className the name of the class from the overridden method
   */
  static final CompileTimeErrorCode INVALID_OVERRIDE_REQUIRED = new CompileTimeErrorCode('INVALID_OVERRIDE_REQUIRED', 71, "Must have at exactly %d required parameters to match the overridden method from '%s'");

  /**
   * 12.10 This: It is a compile-time error if this appears in a top-level function or variable
   * initializer, in a factory constructor, or in a static method or variable initializer, or in the
   * initializer of an instance variable.
   */
  static final CompileTimeErrorCode INVALID_REFERENCE_TO_THIS = new CompileTimeErrorCode('INVALID_REFERENCE_TO_THIS', 72, "Invalid reference to 'this' expression");

  /**
   * 12.7 Maps: It is a compile-time error if the first type argument to a map literal is not
   * String.
   */
  static final CompileTimeErrorCode INVALID_TYPE_ARGUMENT_FOR_KEY = new CompileTimeErrorCode('INVALID_TYPE_ARGUMENT_FOR_KEY', 73, "The first type argument to a map literal must be 'String'");

  /**
   * 12.6 Lists: It is a compile time error if the type argument of a constant list literal includes
   * a type parameter.
   *
   * @name the name of the type parameter
   */
  static final CompileTimeErrorCode INVALID_TYPE_ARGUMENT_IN_CONST_LIST = new CompileTimeErrorCode('INVALID_TYPE_ARGUMENT_IN_CONST_LIST', 74, "Constant list literals cannot include a type parameter as a type argument, such as '%s'");

  /**
   * 12.7 Maps: It is a compile time error if the type arguments of a constant map literal include a
   * type parameter.
   *
   * @name the name of the type parameter
   */
  static final CompileTimeErrorCode INVALID_TYPE_ARGUMENT_IN_CONST_MAP = new CompileTimeErrorCode('INVALID_TYPE_ARGUMENT_IN_CONST_MAP', 75, "Constant map literals cannot include a type parameter as a type argument, such as '%s'");

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
  static final CompileTimeErrorCode INVALID_URI = new CompileTimeErrorCode('INVALID_URI', 76, "Invalid URI syntax: '%s'");

  /**
   * 13.13 Break: It is a compile-time error if no such statement <i>s<sub>E</sub></i> exists within
   * the innermost function in which <i>s<sub>b</sub></i> occurs.
   *
   * 13.14 Continue: It is a compile-time error if no such statement or case clause
   * <i>s<sub>E</sub></i> exists within the innermost function in which <i>s<sub>c</sub></i> occurs.
   *
   * @param labelName the name of the unresolvable label
   */
  static final CompileTimeErrorCode LABEL_IN_OUTER_SCOPE = new CompileTimeErrorCode('LABEL_IN_OUTER_SCOPE', 77, "Cannot reference label '%s' declared in an outer method");

  /**
   * 13.13 Break: It is a compile-time error if no such statement <i>s<sub>E</sub></i> exists within
   * the innermost function in which <i>s<sub>b</sub></i> occurs.
   *
   * 13.14 Continue: It is a compile-time error if no such statement or case clause
   * <i>s<sub>E</sub></i> exists within the innermost function in which <i>s<sub>c</sub></i> occurs.
   *
   * @param labelName the name of the unresolvable label
   */
  static final CompileTimeErrorCode LABEL_UNDEFINED = new CompileTimeErrorCode('LABEL_UNDEFINED', 78, "Cannot reference undefined label '%s'");

  /**
   * 7 Classes: It is a compile time error if a class <i>C</i> declares a member with the same name
   * as <i>C</i>.
   */
  static final CompileTimeErrorCode MEMBER_WITH_CLASS_NAME = new CompileTimeErrorCode('MEMBER_WITH_CLASS_NAME', 79, "Class members cannot have the same name as the enclosing class");

  /**
   * 7.2 Getters: It is a compile-time error if a class has both a getter and a method with the same
   * name.
   *
   * @param name the conflicting name of the getter and method
   */
  static final CompileTimeErrorCode METHOD_AND_GETTER_WITH_SAME_NAME = new CompileTimeErrorCode('METHOD_AND_GETTER_WITH_SAME_NAME', 80, "'%s' cannot be used to name a method, there is already a getter with the same name");

  /**
   * 12.1 Constants: A constant expression is ... a constant list literal.
   */
  static final CompileTimeErrorCode MISSING_CONST_IN_LIST_LITERAL = new CompileTimeErrorCode('MISSING_CONST_IN_LIST_LITERAL', 81, "List literals must be prefixed with 'const' when used as a constant expression");

  /**
   * 12.1 Constants: A constant expression is ... a constant map literal.
   */
  static final CompileTimeErrorCode MISSING_CONST_IN_MAP_LITERAL = new CompileTimeErrorCode('MISSING_CONST_IN_MAP_LITERAL', 82, "Map literals must be prefixed with 'const' when used as a constant expression");

  /**
   * 9 Mixins: It is a compile-time error if a declared or derived mixin explicitly declares a
   * constructor.
   *
   * @param typeName the name of the mixin that is invalid
   */
  static final CompileTimeErrorCode MIXIN_DECLARES_CONSTRUCTOR = new CompileTimeErrorCode('MIXIN_DECLARES_CONSTRUCTOR', 83, "The class '%s' cannot be used as a mixin because it declares a constructor");

  /**
   * 9 Mixins: It is a compile-time error if a mixin is derived from a class whose superclass is not
   * Object.
   *
   * @param typeName the name of the mixin that is invalid
   */
  static final CompileTimeErrorCode MIXIN_INHERITS_FROM_NOT_OBJECT = new CompileTimeErrorCode('MIXIN_INHERITS_FROM_NOT_OBJECT', 84, "The class '%s' cannot be used as a mixin because it extends a class other than Object");

  /**
   * 9.1 Mixin Application: It is a compile-time error if <i>M</i> does not denote a class or mixin
   * available in the immediately enclosing scope.
   */
  static final CompileTimeErrorCode MIXIN_OF_NON_CLASS = new CompileTimeErrorCode('MIXIN_OF_NON_CLASS', 85, "Classes can only mixin other classes");

  /**
   * 9 Mixins: It is a compile-time error if a declared or derived mixin refers to super.
   */
  static final CompileTimeErrorCode MIXIN_REFERENCES_SUPER = new CompileTimeErrorCode('MIXIN_REFERENCES_SUPER', 86, "The class '%s' cannot be used as a mixin because it references 'super'");

  /**
   * 9.1 Mixin Application: It is a compile-time error if <i>S</i> does not denote a class available
   * in the immediately enclosing scope.
   */
  static final CompileTimeErrorCode MIXIN_WITH_NON_CLASS_SUPERCLASS = new CompileTimeErrorCode('MIXIN_WITH_NON_CLASS_SUPERCLASS', 87, "Mixin can only be applied to class");

  /**
   * 7.6.1 Generative Constructors: A generative constructor may be redirecting, in which case its
   * only action is to invoke another generative constructor.
   */
  static final CompileTimeErrorCode MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS = new CompileTimeErrorCode('MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS', 88, "Constructor may have at most one 'this' redirection");

  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. Then <i>k</i> may
   * include at most one superinitializer in its initializer list or a compile time error occurs.
   */
  static final CompileTimeErrorCode MULTIPLE_SUPER_INITIALIZERS = new CompileTimeErrorCode('MULTIPLE_SUPER_INITIALIZERS', 89, "Constructor may have at most one 'super' initializer");

  /**
   * 12.11.1 New: It is a compile time error if <i>S</i> is not a generic type with <i>m</i> type
   * parameters.
   *
   * @param typeName the name of the type being referenced (<i>S</i>)
   * @param parameterCount the number of type parameters that were declared
   * @param argumentCount the number of type arguments provided
   * @see CompileTimeErrorCode#CONST_WITH_INVALID_TYPE_PARAMETERS
   * @see StaticTypeWarningCode#WRONG_NUMBER_OF_TYPE_ARGUMENTS
   */
  static final CompileTimeErrorCode NEW_WITH_INVALID_TYPE_PARAMETERS = new CompileTimeErrorCode('NEW_WITH_INVALID_TYPE_PARAMETERS', 90, "The type '%s' is declared with %d type parameters, but %d type arguments were given");

  /**
   * 11 Metadata: Metadata consists of a series of annotations, each of which begin with the
   * character @, followed by a constant expression that must be either a reference to a
   * compile-time constant variable, or a call to a constant constructor.
   */
  static final CompileTimeErrorCode NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS = new CompileTimeErrorCode('NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS', 91, "Annotation creation must have arguments");

  /**
   * 7.6.1 Generative Constructors: If no superinitializer is provided, an implicit superinitializer
   * of the form <b>super</b>() is added at the end of <i>k</i>'s initializer list, unless the
   * enclosing class is class <i>Object</i>.
   *
   * 7.6.1 Generative constructors. It is a compile-time error if class <i>S</i> does not declare a
   * generative constructor named <i>S</i> (respectively <i>S.id</i>)
   */
  static final CompileTimeErrorCode NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT = new CompileTimeErrorCode('NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT', 92, "The class '%s' does not have a default constructor");

  /**
   * 7.6 Constructors: Iff no constructor is specified for a class <i>C</i>, it implicitly has a
   * default constructor C() : <b>super<b>() {}, unless <i>C</i> is class <i>Object</i>.
   *
   * 7.6.1 Generative constructors. It is a compile-time error if class <i>S</i> does not declare a
   * generative constructor named <i>S</i> (respectively <i>S.id</i>)
   */
  static final CompileTimeErrorCode NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT = new CompileTimeErrorCode('NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT', 93, "The class '%s' does not have a default constructor");

  /**
   * 13.2 Expression Statements: It is a compile-time error if a non-constant map literal that has
   * no explicit type arguments appears in a place where a statement is expected.
   */
  static final CompileTimeErrorCode NON_CONST_MAP_AS_EXPRESSION_STATEMENT = new CompileTimeErrorCode('NON_CONST_MAP_AS_EXPRESSION_STATEMENT', 94, "A non-constant map literal without type arguments cannot be used as an expression statement");

  /**
   * 13.9 Switch: Given a switch statement of the form <i>switch (e) { label<sub>11</sub> &hellip;
   * label<sub>1j1</sub> case e<sub>1</sub>: s<sub>1</sub> &hellip; label<sub>n1</sub> &hellip;
   * label<sub>njn</sub> case e<sub>n</sub>: s<sub>n</sub> default: s<sub>n+1</sub>}</i> or the form
   * <i>switch (e) { label<sub>11</sub> &hellip; label<sub>1j1</sub> case e<sub>1</sub>:
   * s<sub>1</sub> &hellip; label<sub>n1</sub> &hellip; label<sub>njn</sub> case e<sub>n</sub>:
   * s<sub>n</sub>}</i>, it is a compile-time error if the expressions <i>e<sub>k</sub></i> are not
   * compile-time constants, for all <i>1 &lt;= k &lt;= n</i>.
   */
  static final CompileTimeErrorCode NON_CONSTANT_CASE_EXPRESSION = new CompileTimeErrorCode('NON_CONSTANT_CASE_EXPRESSION', 95, "Case expressions must be constant");

  /**
   * 6.2.2 Optional Formals: It is a compile-time error if the default value of an optional
   * parameter is not a compile-time constant.
   */
  static final CompileTimeErrorCode NON_CONSTANT_DEFAULT_VALUE = new CompileTimeErrorCode('NON_CONSTANT_DEFAULT_VALUE', 96, "Default values of an optional parameter must be constant");

  /**
   * 12.6 Lists: It is a compile time error if an element of a constant list literal is not a
   * compile-time constant.
   */
  static final CompileTimeErrorCode NON_CONSTANT_LIST_ELEMENT = new CompileTimeErrorCode('NON_CONSTANT_LIST_ELEMENT', 97, "'const' lists must have all constant values");

  /**
   * 12.7 Maps: It is a compile time error if either a key or a value of an entry in a constant map
   * literal is not a compile-time constant.
   */
  static final CompileTimeErrorCode NON_CONSTANT_MAP_KEY = new CompileTimeErrorCode('NON_CONSTANT_MAP_KEY', 98, "The keys in a map must be constant");

  /**
   * 12.7 Maps: It is a compile time error if either a key or a value of an entry in a constant map
   * literal is not a compile-time constant.
   */
  static final CompileTimeErrorCode NON_CONSTANT_MAP_VALUE = new CompileTimeErrorCode('NON_CONSTANT_MAP_VALUE', 99, "The values in a 'const' map must be constant");

  /**
   * 11 Metadata: Metadata consists of a series of annotations, each of which begin with the
   * character @, followed by a constant expression that must be either a reference to a
   * compile-time constant variable, or a call to a constant constructor.
   */
  static final CompileTimeErrorCode NON_CONSTANT_ANNOTATION_CONSTRUCTOR = new CompileTimeErrorCode('NON_CONSTANT_ANNOTATION_CONSTRUCTOR', 100, "Annotation creation can use only 'const' constructor");

  /**
   * 7.6.3 Constant Constructors: Any expression that appears within the initializer list of a
   * constant constructor must be a potentially constant expression, or a compile-time error occurs.
   */
  static final CompileTimeErrorCode NON_CONSTANT_VALUE_IN_INITIALIZER = new CompileTimeErrorCode('NON_CONSTANT_VALUE_IN_INITIALIZER', 101, "Initializer expressions in constant constructors must be constants");

  /**
   * 12.14.2 Binding Actuals to Formals: It is a static warning if <i>m < h</i> or if <i>m > n</i>.
   *
   * 12.11.2 Const: It is a compile-time error if evaluation of a constant object results in an
   * uncaught exception being thrown.
   *
   * @param requiredCount the expected number of required arguments
   * @param argumentCount the actual number of positional arguments given
   */
  static final CompileTimeErrorCode NOT_ENOUGH_REQUIRED_ARGUMENTS = new CompileTimeErrorCode('NOT_ENOUGH_REQUIRED_ARGUMENTS', 102, "%d required argument(s) expected, but %d found");

  /**
   * 7.6.1 Generative Constructors: Let <i>C</i> be the class in which the superinitializer appears
   * and let <i>S</i> be the superclass of <i>C</i>. Let <i>k</i> be a generative constructor. It is
   * a compile-time error if class <i>S</i> does not declare a generative constructor named <i>S</i>
   * (respectively <i>S.id</i>)
   */
  static final CompileTimeErrorCode NON_GENERATIVE_CONSTRUCTOR = new CompileTimeErrorCode('NON_GENERATIVE_CONSTRUCTOR', 103, "The generative constructor '%s' expected, but factory found");

  /**
   * 7.9 Superclasses: It is a compile-time error to specify an extends clause for class Object.
   */
  static final CompileTimeErrorCode OBJECT_CANNOT_EXTEND_ANOTHER_CLASS = new CompileTimeErrorCode('OBJECT_CANNOT_EXTEND_ANOTHER_CLASS', 104, "");

  /**
   * 7.1.1 Operators: It is a compile-time error to declare an optional parameter in an operator.
   */
  static final CompileTimeErrorCode OPTIONAL_PARAMETER_IN_OPERATOR = new CompileTimeErrorCode('OPTIONAL_PARAMETER_IN_OPERATOR', 105, "Optional parameters are not allowed when defining an operator");

  /**
   * 14.3 Parts: It is a compile time error if the contents of the URI are not a valid part
   * declaration.
   *
   * @param uri the uri pointing to a non-library declaration
   */
  static final CompileTimeErrorCode PART_OF_NON_PART = new CompileTimeErrorCode('PART_OF_NON_PART', 106, "The included part '%s' must have a part-of directive");

  /**
   * 14.1 Imports: It is a compile-time error if the current library declares a top-level member
   * named <i>p</i>.
   */
  static final CompileTimeErrorCode PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER = new CompileTimeErrorCode('PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER', 107, "The name '%s' is already used as an import prefix and cannot be used to name a top-level element");

  /**
   * 6.2.2 Optional Formals: It is a compile-time error if the name of a named optional parameter
   * begins with an '_' character.
   */
  static final CompileTimeErrorCode PRIVATE_OPTIONAL_PARAMETER = new CompileTimeErrorCode('PRIVATE_OPTIONAL_PARAMETER', 108, "Named optional parameters cannot start with an underscore");

  /**
   * 12.1 Constants: It is a compile-time error if the value of a compile-time constant expression
   * depends on itself.
   */
  static final CompileTimeErrorCode RECURSIVE_COMPILE_TIME_CONSTANT = new CompileTimeErrorCode('RECURSIVE_COMPILE_TIME_CONSTANT', 109, "");

  /**
   * 7.6.1 Generative Constructors: A generative constructor may be redirecting, in which case its
   * only action is to invoke another generative constructor.
   *
   * TODO(scheglov) review this later, there are no explicit "it is a compile-time error" in
   * specification. But it was added to the co19 and there is same error for factories.
   *
   * https://code.google.com/p/dart/issues/detail?id=954
   */
  static final CompileTimeErrorCode RECURSIVE_CONSTRUCTOR_REDIRECT = new CompileTimeErrorCode('RECURSIVE_CONSTRUCTOR_REDIRECT', 110, "Cycle in redirecting generative constructors");

  /**
   * 7.6.2 Factories: It is a compile-time error if a redirecting factory constructor redirects to
   * itself, either directly or indirectly via a sequence of redirections.
   */
  static final CompileTimeErrorCode RECURSIVE_FACTORY_REDIRECT = new CompileTimeErrorCode('RECURSIVE_FACTORY_REDIRECT', 111, "Cycle in redirecting factory constructors");

  /**
   * 15.3.1 Typedef: It is a compile-time error if a typedef refers to itself via a chain of
   * references that does not include a class type.
   */
  static final CompileTimeErrorCode RECURSIVE_FUNCTION_TYPE_ALIAS = new CompileTimeErrorCode('RECURSIVE_FUNCTION_TYPE_ALIAS', 112, "");

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
  static final CompileTimeErrorCode RECURSIVE_INTERFACE_INHERITANCE = new CompileTimeErrorCode('RECURSIVE_INTERFACE_INHERITANCE', 113, "'%s' cannot be a superinterface of itself: %s");

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
  static final CompileTimeErrorCode RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS = new CompileTimeErrorCode('RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS', 114, "'%s' cannot extend itself");

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
  static final CompileTimeErrorCode RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS = new CompileTimeErrorCode('RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS', 115, "'%s' cannot implement itself");

  /**
   * 7.6.2 Factories: It is a compile-time error if <i>k</i> is prefixed with the const modifier but
   * <i>k'</i> is not a constant constructor.
   */
  static final CompileTimeErrorCode REDIRECT_TO_NON_CONST_CONSTRUCTOR = new CompileTimeErrorCode('REDIRECT_TO_NON_CONST_CONSTRUCTOR', 116, "Constant factory constructor cannot delegate to a non-constant constructor");

  /**
   * 13.3 Local Variable Declaration: It is a compile-time error if <i>e</i> refers to the name
   * <i>v</i> or the name <i>v=</i>.
   */
  static final CompileTimeErrorCode REFERENCE_TO_DECLARED_VARIABLE_IN_INITIALIZER = new CompileTimeErrorCode('REFERENCE_TO_DECLARED_VARIABLE_IN_INITIALIZER', 117, "The name '%s' cannot be referenced in the initializer of a variable with the same name");

  /**
   * 16.1.1 Reserved Words: A reserved word may not be used as an identifier; it is a compile-time
   * error if a reserved word is used where an identifier is expected.
   */
  static final CompileTimeErrorCode RESERVED_WORD_AS_IDENTIFIER = new CompileTimeErrorCode('RESERVED_WORD_AS_IDENTIFIER', 118, "");

  /**
   * 12.8.1 Rethrow: It is a compile-time error if an expression of the form <i>rethrow;</i> is not
   * enclosed within a on-catch clause.
   */
  static final CompileTimeErrorCode RETHROW_OUTSIDE_CATCH = new CompileTimeErrorCode('RETHROW_OUTSIDE_CATCH', 119, "rethrow must be inside of a catch clause");

  /**
   * 13.11 Return: It is a compile-time error if a return statement of the form <i>return e;</i>
   * appears in a generative constructor.
   */
  static final CompileTimeErrorCode RETURN_IN_GENERATIVE_CONSTRUCTOR = new CompileTimeErrorCode('RETURN_IN_GENERATIVE_CONSTRUCTOR', 120, "Constructors cannot return a value");

  /**
   * 6.1 Function Declarations: It is a compile-time error to preface a function declaration with
   * the built-in identifier static.
   */
  static final CompileTimeErrorCode STATIC_TOP_LEVEL_FUNCTION = new CompileTimeErrorCode('STATIC_TOP_LEVEL_FUNCTION', 121, "");

  /**
   * 5 Variables: It is a compile-time error to preface a top level variable declaration with the
   * built-in identifier static.
   */
  static final CompileTimeErrorCode STATIC_TOP_LEVEL_VARIABLE = new CompileTimeErrorCode('STATIC_TOP_LEVEL_VARIABLE', 122, "");

  /**
   * 12.15.4 Super Invocation: A super method invocation <i>i</i> has the form
   * <i>super.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;
   * x<sub>n+k</sub>: a<sub>n+k</sub>)</i>. It is a compile-time error if a super method invocation
   * occurs in a top-level function or variable initializer, in an instance variable initializer or
   * initializer list, in class Object, in a factory constructor, or in a static method or variable
   * initializer.
   */
  static final CompileTimeErrorCode SUPER_IN_INVALID_CONTEXT = new CompileTimeErrorCode('SUPER_IN_INVALID_CONTEXT', 123, "Invalid context for 'super' invocation");

  /**
   * 7.6.1 Generative Constructors: A generative constructor may be redirecting, in which case its
   * only action is to invoke another generative constructor.
   */
  static final CompileTimeErrorCode SUPER_IN_REDIRECTING_CONSTRUCTOR = new CompileTimeErrorCode('SUPER_IN_REDIRECTING_CONSTRUCTOR', 124, "The redirecting constructor cannot have a 'super' initializer");

  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It is a compile-time
   * error if a generative constructor of class Object includes a superinitializer.
   */
  static final CompileTimeErrorCode SUPER_INITIALIZER_IN_OBJECT = new CompileTimeErrorCode('SUPER_INITIALIZER_IN_OBJECT', 125, "");

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
  static final CompileTimeErrorCode TYPE_ARGUMENT_NOT_MATCHING_BOUNDS = new CompileTimeErrorCode('TYPE_ARGUMENT_NOT_MATCHING_BOUNDS', 126, "'%s' does not extend '%s'");

  /**
   * 15.3.1 Typedef: It is a compile-time error if a typedef refers to itself via a chain of
   * references that does not include a class declaration.
   */
  static final CompileTimeErrorCode TYPE_ALIAS_CANNOT_REFERENCE_ITSELF = new CompileTimeErrorCode('TYPE_ALIAS_CANNOT_REFERENCE_ITSELF', 127, "Type alias cannot reference itself directly or via other typedefs");

  /**
   * 12.11.2 Const: It is a compile-time error if <i>T</i> is not a class accessible in the current
   * scope, optionally followed by type arguments.
   */
  static final CompileTimeErrorCode UNDEFINED_CLASS = new CompileTimeErrorCode('UNDEFINED_CLASS', 128, "Undefined class '%s'");

  /**
   * 7.6.1 Generative Constructors: Let <i>C</i> be the class in which the superinitializer appears
   * and let <i>S</i> be the superclass of <i>C</i>. Let <i>k</i> be a generative constructor. It is
   * a compile-time error if class <i>S</i> does not declare a generative constructor named <i>S</i>
   * (respectively <i>S.id</i>)
   */
  static final CompileTimeErrorCode UNDEFINED_CONSTRUCTOR_IN_INITIALIZER = new CompileTimeErrorCode('UNDEFINED_CONSTRUCTOR_IN_INITIALIZER', 129, "The class '%s' does not have a generative constructor '%s'");

  /**
   * 7.6.1 Generative Constructors: Let <i>C</i> be the class in which the superinitializer appears
   * and let <i>S</i> be the superclass of <i>C</i>. Let <i>k</i> be a generative constructor. It is
   * a compile-time error if class <i>S</i> does not declare a generative constructor named <i>S</i>
   * (respectively <i>S.id</i>)
   */
  static final CompileTimeErrorCode UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT = new CompileTimeErrorCode('UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT', 130, "The class '%s' does not have a default generative constructor");

  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. Each final instance
   * variable <i>f</i> declared in the immediately enclosing class must have an initializer in
   * <i>k</i>'s initializer list unless it has already been initialized by one of the following
   * means:
   * <ol>
   * * Initialization at the declaration of <i>f</i>.
   * * Initialization by means of an initializing formal of <i>k</i>.
   * </ol>
   * or a compile-time error occurs.
   */
  static final CompileTimeErrorCode UNINITIALIZED_FINAL_FIELD = new CompileTimeErrorCode('UNINITIALIZED_FINAL_FIELD', 131, "");

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
  static final CompileTimeErrorCode UNDEFINED_NAMED_PARAMETER = new CompileTimeErrorCode('UNDEFINED_NAMED_PARAMETER', 132, "The named parameter '%s' is not defined");

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
  static final CompileTimeErrorCode URI_DOES_NOT_EXIST = new CompileTimeErrorCode('URI_DOES_NOT_EXIST', 133, "Target of URI does not exist: '%s'");

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
  static final CompileTimeErrorCode URI_WITH_INTERPOLATION = new CompileTimeErrorCode('URI_WITH_INTERPOLATION', 134, "URIs cannot use string interpolation");

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
  static final CompileTimeErrorCode WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR = new CompileTimeErrorCode('WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR', 135, "Operator '%s' should declare exactly %d parameter(s), but %d found");

  /**
   * 7.1.1 Operators: It is a compile time error if the arity of the user-declared operator - is not
   * 0 or 1.
   *
   * @param actualNumberOfParameters the number of parameters found in the operator declaration
   */
  static final CompileTimeErrorCode WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS = new CompileTimeErrorCode('WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS', 136, "Operator '-' should declare 0 or 1 parameter, but %d found");

  /**
   * 7.3 Setters: It is a compile-time error if a setter's formal parameter list does not include
   * exactly one required formal parameter <i>p</i>.
   */
  static final CompileTimeErrorCode WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER = new CompileTimeErrorCode('WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER', 137, "Setters should declare exactly one required parameter");
  static final List<CompileTimeErrorCode> values = [AMBIGUOUS_EXPORT, AMBIGUOUS_IMPORT, ARGUMENT_DEFINITION_TEST_NON_PARAMETER, BUILT_IN_IDENTIFIER_AS_TYPE, BUILT_IN_IDENTIFIER_AS_TYPE_NAME, BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME, BUILT_IN_IDENTIFIER_AS_TYPE_VARIABLE_NAME, CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS, COMPILE_TIME_CONSTANT_RAISES_EXCEPTION, CONFLICTING_GETTER_AND_METHOD, CONFLICTING_METHOD_AND_GETTER, CONFLICTING_CONSTRUCTOR_NAME_AND_FIELD, CONFLICTING_CONSTRUCTOR_NAME_AND_METHOD, CONST_CONSTRUCTOR_THROWS_EXCEPTION, CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD, CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE, CONST_FORMAL_PARAMETER, CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, CONST_INSTANCE_FIELD, CONST_EVAL_TYPE_BOOL, CONST_EVAL_TYPE_BOOL_NUM_STRING, CONST_EVAL_TYPE_INT, CONST_EVAL_TYPE_NUM, CONST_EVAL_THROWS_EXCEPTION, CONST_EVAL_THROWS_IDBZE, CONST_WITH_INVALID_TYPE_PARAMETERS, CONST_WITH_NON_CONST, CONST_WITH_NON_CONSTANT_ARGUMENT, CONST_WITH_NON_TYPE, CONST_WITH_TYPE_PARAMETERS, CONST_WITH_UNDEFINED_CONSTRUCTOR, CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT, DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS, DUPLICATE_CONSTRUCTOR_DEFAULT, DUPLICATE_CONSTRUCTOR_NAME, DUPLICATE_DEFINITION, DUPLICATE_DEFINITION_INHERITANCE, DUPLICATE_NAMED_ARGUMENT, EXPORT_INTERNAL_LIBRARY, EXPORT_OF_NON_LIBRARY, EXTENDS_NON_CLASS, EXTENDS_DISALLOWED_CLASS, EXTRA_POSITIONAL_ARGUMENTS, FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS, FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION, FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER, FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR, FINAL_INITIALIZED_MULTIPLE_TIMES, FIELD_INITIALIZER_FACTORY_CONSTRUCTOR, FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR, GETTER_AND_METHOD_WITH_SAME_NAME, IMPLEMENTS_DISALLOWED_CLASS, IMPLEMENTS_DYNAMIC, IMPLEMENTS_NON_CLASS, IMPLEMENTS_REPEATED, IMPLICIT_THIS_REFERENCE_IN_INITIALIZER, IMPORT_INTERNAL_LIBRARY, IMPORT_OF_NON_LIBRARY, INCONSISTENT_CASE_EXPRESSION_TYPES, INITIALIZER_FOR_NON_EXISTANT_FIELD, INITIALIZER_FOR_STATIC_FIELD, INITIALIZING_FORMAL_FOR_NON_EXISTANT_FIELD, INITIALIZING_FORMAL_FOR_STATIC_FIELD, INSTANCE_MEMBER_ACCESS_FROM_STATIC, INVALID_ANNOTATION, INVALID_CONSTANT, INVALID_CONSTRUCTOR_NAME, INVALID_FACTORY_NAME_NOT_A_CLASS, INVALID_OVERRIDE_NAMED, INVALID_OVERRIDE_POSITIONAL, INVALID_OVERRIDE_REQUIRED, INVALID_REFERENCE_TO_THIS, INVALID_TYPE_ARGUMENT_FOR_KEY, INVALID_TYPE_ARGUMENT_IN_CONST_LIST, INVALID_TYPE_ARGUMENT_IN_CONST_MAP, INVALID_URI, LABEL_IN_OUTER_SCOPE, LABEL_UNDEFINED, MEMBER_WITH_CLASS_NAME, METHOD_AND_GETTER_WITH_SAME_NAME, MISSING_CONST_IN_LIST_LITERAL, MISSING_CONST_IN_MAP_LITERAL, MIXIN_DECLARES_CONSTRUCTOR, MIXIN_INHERITS_FROM_NOT_OBJECT, MIXIN_OF_NON_CLASS, MIXIN_REFERENCES_SUPER, MIXIN_WITH_NON_CLASS_SUPERCLASS, MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS, MULTIPLE_SUPER_INITIALIZERS, NEW_WITH_INVALID_TYPE_PARAMETERS, NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS, NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT, NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT, NON_CONST_MAP_AS_EXPRESSION_STATEMENT, NON_CONSTANT_CASE_EXPRESSION, NON_CONSTANT_DEFAULT_VALUE, NON_CONSTANT_LIST_ELEMENT, NON_CONSTANT_MAP_KEY, NON_CONSTANT_MAP_VALUE, NON_CONSTANT_ANNOTATION_CONSTRUCTOR, NON_CONSTANT_VALUE_IN_INITIALIZER, NOT_ENOUGH_REQUIRED_ARGUMENTS, NON_GENERATIVE_CONSTRUCTOR, OBJECT_CANNOT_EXTEND_ANOTHER_CLASS, OPTIONAL_PARAMETER_IN_OPERATOR, PART_OF_NON_PART, PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER, PRIVATE_OPTIONAL_PARAMETER, RECURSIVE_COMPILE_TIME_CONSTANT, RECURSIVE_CONSTRUCTOR_REDIRECT, RECURSIVE_FACTORY_REDIRECT, RECURSIVE_FUNCTION_TYPE_ALIAS, RECURSIVE_INTERFACE_INHERITANCE, RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS, RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS, REDIRECT_TO_NON_CONST_CONSTRUCTOR, REFERENCE_TO_DECLARED_VARIABLE_IN_INITIALIZER, RESERVED_WORD_AS_IDENTIFIER, RETHROW_OUTSIDE_CATCH, RETURN_IN_GENERATIVE_CONSTRUCTOR, STATIC_TOP_LEVEL_FUNCTION, STATIC_TOP_LEVEL_VARIABLE, SUPER_IN_INVALID_CONTEXT, SUPER_IN_REDIRECTING_CONSTRUCTOR, SUPER_INITIALIZER_IN_OBJECT, TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, UNDEFINED_CLASS, UNDEFINED_CONSTRUCTOR_IN_INITIALIZER, UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT, UNINITIALIZED_FINAL_FIELD, UNDEFINED_NAMED_PARAMETER, URI_DOES_NOT_EXIST, URI_WITH_INTERPOLATION, WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR, WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS, WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER];

  /// The name of this enum constant, as declared in the enum declaration.
  final String name;

  /// The position in the enum declaration.
  final int ordinal;

  /**
   * The message template used to create the message to be displayed for this error.
   */
  String _message;

  /**
   * Initialize a newly created error code to have the given message.
   *
   * @param message the message template used to create the message to be displayed for the error
   */
  CompileTimeErrorCode(this.name, this.ordinal, String message) {
    this._message = message;
  }
  ErrorSeverity get errorSeverity => ErrorType.COMPILE_TIME_ERROR.severity;
  String get message => _message;
  ErrorType get type => ErrorType.COMPILE_TIME_ERROR;
  int compareTo(CompileTimeErrorCode other) => ordinal - other.ordinal;
  int get hashCode => ordinal;
  String toString() => name;
}
/**
 * The enumeration `PubSuggestionCode` defines the suggestions used for reporting deviations
 * from pub best practices. The convention for this class is for the name of the bad practice to
 * indicate the problem that caused the suggestion to be generated and for the message to explain
 * what is wrong and, when appropriate, how the situation can be corrected.
 */
class PubSuggestionCode implements Comparable<PubSuggestionCode>, ErrorCode {

  /**
   * It is a bad practice for a source file in a package "lib" directory hierarchy to traverse
   * outside that directory hierarchy. For example, a source file in the "lib" directory should not
   * contain a directive such as `import '../web/some.dart'` which references a file outside
   * the lib directory.
   */
  static final PubSuggestionCode FILE_IMPORT_INSIDE_LIB_REFERENCES_FILE_OUTSIDE = new PubSuggestionCode('FILE_IMPORT_INSIDE_LIB_REFERENCES_FILE_OUTSIDE', 0, "A file in the 'lib' directory hierarchy should not reference a file outside that hierarchy");

  /**
   * It is a bad practice for a source file ouside a package "lib" directory hierarchy to traverse
   * into that directory hierarchy. For example, a source file in the "web" directory should not
   * contain a directive such as `import '../lib/some.dart'` which references a file inside
   * the lib directory.
   */
  static final PubSuggestionCode FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE = new PubSuggestionCode('FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE', 1, "A file outside the 'lib' directory hierarchy should not reference a file inside that hierarchy. Use a package: reference instead.");

  /**
   * It is a bad practice for a package import to reference anything outside the given package, or
   * more generally, it is bad practice for a package import to contain a "..". For example, a
   * source file should not contain a directive such as `import 'package:foo/../some.dart'`.
   */
  static final PubSuggestionCode PACKAGE_IMPORT_CONTAINS_DOT_DOT = new PubSuggestionCode('PACKAGE_IMPORT_CONTAINS_DOT_DOT', 2, "A package import should not contain '..'");
  static final List<PubSuggestionCode> values = [FILE_IMPORT_INSIDE_LIB_REFERENCES_FILE_OUTSIDE, FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE, PACKAGE_IMPORT_CONTAINS_DOT_DOT];

  /// The name of this enum constant, as declared in the enum declaration.
  final String name;

  /// The position in the enum declaration.
  final int ordinal;

  /**
   * The message template used to create the message to be displayed for this error.
   */
  String _message;

  /**
   * Initialize a newly created error code to have the given message.
   *
   * @param message the message template used to create the message to be displayed for the error
   */
  PubSuggestionCode(this.name, this.ordinal, String message) {
    this._message = message;
  }
  ErrorSeverity get errorSeverity => ErrorType.PUB_SUGGESTION.severity;
  String get message => _message;
  ErrorType get type => ErrorType.PUB_SUGGESTION;
  int compareTo(PubSuggestionCode other) => ordinal - other.ordinal;
  int get hashCode => ordinal;
  String toString() => name;
}
/**
 * The enumeration `StaticWarningCode` defines the error codes used for static warnings. The
 * convention for this class is for the name of the error code to indicate the problem that caused
 * the error to be generated and for the error message to explain what is wrong and, when
 * appropriate, how the problem can be corrected.
 *
 * @coverage dart.engine.error
 */
class StaticWarningCode implements Comparable<StaticWarningCode>, ErrorCode {

  /**
   * 14.1 Imports: If a name <i>N</i> is referenced by a library <i>L</i> and <i>N</i> is introduced
   * into the top level scope <i>L</i> by more than one import then:
   * <ol>
   * * It is a static warning if <i>N</i> is used as a type annotation.
   * * In checked mode, it is a dynamic error if <i>N</i> is used as a type annotation and
   * referenced during a subtype test.
   * * Otherwise, it is a compile-time error.
   * </ol>
   *
   * @param ambiguousTypeName the name of the ambiguous type
   * @param firstLibraryName the name of the first library that the type is found
   * @param secondLibraryName the name of the second library that the type is found
   */
  static final StaticWarningCode AMBIGUOUS_IMPORT = new StaticWarningCode('AMBIGUOUS_IMPORT', 0, "The type '%s' is defined in the libraries '%s' and '%s'");

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
   */
  static final StaticWarningCode ARGUMENT_TYPE_NOT_ASSIGNABLE = new StaticWarningCode('ARGUMENT_TYPE_NOT_ASSIGNABLE', 1, "The argument type '%s' cannot be assigned to the parameter type '%s'");

  /**
   * 5 Variables: Attempting to assign to a final variable elsewhere will cause a NoSuchMethodError
   * to be thrown, because no setter is defined for it. The assignment will also give rise to a
   * static warning for the same reason.
   */
  static final StaticWarningCode ASSIGNMENT_TO_FINAL = new StaticWarningCode('ASSIGNMENT_TO_FINAL', 2, "Final variables cannot be assigned a value");

  /**
   * 13.9 Switch: It is a static warning if the last statement of the statement sequence
   * <i>s<sub>k</sub></i> is not a break, continue, return or throw statement.
   */
  static final StaticWarningCode CASE_BLOCK_NOT_TERMINATED = new StaticWarningCode('CASE_BLOCK_NOT_TERMINATED', 3, "The last statement of the 'case' should be 'break', 'continue', 'return' or 'throw'");

  /**
   * 12.32 Type Cast: It is a static warning if <i>T</i> does not denote a type available in the
   * current lexical scope.
   */
  static final StaticWarningCode CAST_TO_NON_TYPE = new StaticWarningCode('CAST_TO_NON_TYPE', 4, "The name '%s' is not a type and cannot be used in an 'as' expression");

  /**
   * 16.1.2 Comments: A token of the form <i>[new c](uri)</i> will be replaced by a link in the
   * formatted output. The link will point at the constructor named <i>c</i> in <i>L</i>. The title
   * of the link will be <i>c</i>. It is a static warning if uri is not the URI of a dart library
   * <i>L</i>, or if <i>c</i> is not the name of a constructor of a class declared in the exported
   * namespace of <i>L</i>.
   */
  static final StaticWarningCode COMMENT_REFERENCE_CONSTRUCTOR_NOT_VISIBLE = new StaticWarningCode('COMMENT_REFERENCE_CONSTRUCTOR_NOT_VISIBLE', 5, "");

  /**
   * 16.1.2 Comments: A token of the form <i>[id](uri)</i> will be replaced by a link in the
   * formatted output. The link will point at the declaration named <i>id</i> in <i>L</i>. The title
   * of the link will be <i>id</i>. It is a static warning if uri is not the URI of a dart library
   * <i>L</i>, or if <i>id</i> is not a name declared in the exported namespace of <i>L</i>.
   */
  static final StaticWarningCode COMMENT_REFERENCE_IDENTIFIER_NOT_VISIBLE = new StaticWarningCode('COMMENT_REFERENCE_IDENTIFIER_NOT_VISIBLE', 6, "");

  /**
   * 16.1.2 Comments: It is a static warning if <i>c</i> does not denote a constructor that
   * available in the scope of the documentation comment.
   */
  static final StaticWarningCode COMMENT_REFERENCE_UNDECLARED_CONSTRUCTOR = new StaticWarningCode('COMMENT_REFERENCE_UNDECLARED_CONSTRUCTOR', 7, "");

  /**
   * 16.1.2 Comments: It is a static warning if <i>id</i> does not denote a declaration that
   * available in the scope of the documentation comment.
   */
  static final StaticWarningCode COMMENT_REFERENCE_UNDECLARED_IDENTIFIER = new StaticWarningCode('COMMENT_REFERENCE_UNDECLARED_IDENTIFIER', 8, "");

  /**
   * 16.1.2 Comments: A token of the form <i>[id](uri)</i> will be replaced by a link in the
   * formatted output. The link will point at the declaration named <i>id</i> in <i>L</i>. The title
   * of the link will be <i>id</i>. It is a static warning if uri is not the URI of a dart library
   * <i>L</i>, or if <i>id</i> is not a name declared in the exported namespace of <i>L</i>.
   */
  static final StaticWarningCode COMMENT_REFERENCE_URI_NOT_LIBRARY = new StaticWarningCode('COMMENT_REFERENCE_URI_NOT_LIBRARY', 9, "");

  /**
   * 7.4 Abstract Instance Members: It is a static warning if an abstract member is declared or
   * inherited in a concrete class.
   */
  static final StaticWarningCode CONCRETE_CLASS_WITH_ABSTRACT_MEMBER = new StaticWarningCode('CONCRETE_CLASS_WITH_ABSTRACT_MEMBER', 10, "'%s' must have a method body because '%s' is not abstract");

  /**
   * 7.2 Getters: It is a static warning if a class <i>C</i> declares an instance getter named
   * <i>v</i> and an accessible static member named <i>v</i> or <i>v=</i> is declared in a
   * superclass of <i>C</i>.
   *
   * @param superName the name of the super class declaring a static member
   */
  static final StaticWarningCode CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER = new StaticWarningCode('CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER', 11, "Superclass '%s' declares static member with the same name");

  /**
   * 7.3 Setters: It is a static warning if a class <i>C</i> declares an instance setter named
   * <i>v=</i> and an accessible static member named <i>v=</i> or <i>v</i> is declared in a
   * superclass of <i>C</i>.
   *
   * @param superName the name of the super class declaring a static member
   */
  static final StaticWarningCode CONFLICTING_INSTANCE_SETTER_AND_SUPERCLASS_MEMBER = new StaticWarningCode('CONFLICTING_INSTANCE_SETTER_AND_SUPERCLASS_MEMBER', 12, "Superclass '%s' declares static member with the same name");

  /**
   * 7.2 Getters: It is a static warning if a class declares a static getter named <i>v</i> and also
   * has a non-static setter named <i>v=</i>.
   */
  static final StaticWarningCode CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER = new StaticWarningCode('CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER', 13, "Class '%s' declares non-static setter with the same name");

  /**
   * 7.3 Setters: It is a static warning if a class declares a static setter named <i>v=</i> and
   * also has a non-static member named <i>v</i>.
   */
  static final StaticWarningCode CONFLICTING_STATIC_SETTER_AND_INSTANCE_MEMBER = new StaticWarningCode('CONFLICTING_STATIC_SETTER_AND_INSTANCE_MEMBER', 14, "Class '%s' declares non-static member with the same name");

  /**
   * 12.11.2 Const: Given an instance creation expression of the form <i>const q(a<sub>1</sub>,
   * &hellip; a<sub>n</sub>)</i> it is a static warning if <i>q</i> is the constructor of an
   * abstract class but <i>q</i> is not a factory constructor.
   */
  static final StaticWarningCode CONST_WITH_ABSTRACT_CLASS = new StaticWarningCode('CONST_WITH_ABSTRACT_CLASS', 15, "Abstract classes cannot be created with a 'const' expression");

  /**
   * 12.7 Maps: It is a static warning if the values of any two keys in a map literal are equal.
   */
  static final StaticWarningCode EQUAL_KEYS_IN_MAP = new StaticWarningCode('EQUAL_KEYS_IN_MAP', 16, "Keys in a map cannot be equal");

  /**
   * 14.2 Exports: It is a static warning to export two different libraries with the same name.
   *
   * @param uri1 the uri pointing to a first library
   * @param uri2 the uri pointing to a second library
   * @param name the shared name of the exported libraries
   */
  static final StaticWarningCode EXPORT_DUPLICATED_LIBRARY_NAME = new StaticWarningCode('EXPORT_DUPLICATED_LIBRARY_NAME', 17, "The exported libraries '%s' and '%s' should not have the same name '%s'");

  /**
   * 12.14.2 Binding Actuals to Formals: It is a static warning if <i>m &lt; h</i> or if <i>m &gt;
   * n</i>.
   *
   * @param requiredCount the maximum number of positional arguments
   * @param argumentCount the actual number of positional arguments given
   * @see #NOT_ENOUGH_REQUIRED_ARGUMENTS
   */
  static final StaticWarningCode EXTRA_POSITIONAL_ARGUMENTS = new StaticWarningCode('EXTRA_POSITIONAL_ARGUMENTS', 18, "%d positional arguments expected, but %d found");

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
  static final StaticWarningCode FIELD_INITIALIZER_NOT_ASSIGNABLE = new StaticWarningCode('FIELD_INITIALIZER_NOT_ASSIGNABLE', 19, "The initializer type '%s' cannot be assigned to the field type '%s'");

  /**
   * 7.6.1 Generative Constructors: An initializing formal has the form <i>this.id</i>. It is a
   * static warning if the static type of <i>id</i> is not assignable to <i>T<sub>id</sub></i>.
   *
   * @param parameterType the name of the type of the field formal parameter
   * @param fieldType the name of the type of the field
   */
  static final StaticWarningCode FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE = new StaticWarningCode('FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE', 20, "The parameter type '%s' is incompatable with the field type '%s'");

  /**
   * 5 Variables: It is a static warning if a library, static or local variable <i>v</i> is final
   * and <i>v</i> is not initialized at its point of declaration.
   *
   * @param name the name of the uninitialized final variable
   */
  static final StaticWarningCode FINAL_NOT_INITIALIZED = new StaticWarningCode('FINAL_NOT_INITIALIZED', 21, "The final variable '%s' must be initialized");

  /**
   * 14.1 Imports: It is a static warning to import two different libraries with the same name.
   *
   * @param uri1 the uri pointing to a first library
   * @param uri2 the uri pointing to a second library
   * @param name the shared name of the imported libraries
   */
  static final StaticWarningCode IMPORT_DUPLICATED_LIBRARY_NAME = new StaticWarningCode('IMPORT_DUPLICATED_LIBRARY_NAME', 22, "The imported libraries '%s' and '%s' should not have the same name '%s'");

  /**
   * 8.1.1 Inheritance and Overriding: However, if there are multiple members <i>m<sub>1</sub>,
   * &hellip; m<sub>k</sub></i> with the same name <i>n</i> that would be inherited (because
   * identically named members existed in several superinterfaces) then at most one member is
   * inherited.
   *
   * If some but not all of the <i>m<sub>i</sub>, 1 &lt;= i &lt;= k</i>, are getters, or if some but
   * not all of the <i>m<sub>i</sub></i> are setters, none of the <i>m<sub>i</sub></i> are
   * inherited, and a static warning is issued.
   */
  static final StaticWarningCode INCONSISTENT_METHOD_INHERITANCE_GETTER_AND_METHOD = new StaticWarningCode('INCONSISTENT_METHOD_INHERITANCE_GETTER_AND_METHOD', 23, "'%s' is inherited as a getter and also a method");

  /**
   * 7.1 Instance Methods: It is a static warning if a class <i>C</i> declares an instance method
   * named <i>n</i> and an accessible static member named <i>n</i> is declared in a superclass of
   * <i>C</i>.
   *
   * @param memberName the name of the member with the name conflict
   * @param superclassName the name of the enclosing class that has the static member
   */
  static final StaticWarningCode INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC = new StaticWarningCode('INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC', 24, "'%s' collides with a static member in the superclass '%s'");

  /**
   * 7.6.2 Factories: It is a static warning if <i>M.id</i> is not a constructor name.
   */
  static final StaticWarningCode INVALID_FACTORY_NAME = new StaticWarningCode('INVALID_FACTORY_NAME', 25, "");

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
  static final StaticWarningCode INVALID_GETTER_OVERRIDE_RETURN_TYPE = new StaticWarningCode('INVALID_GETTER_OVERRIDE_RETURN_TYPE', 26, "The return type '%s' is not assignable to '%s' as required from getter it is overriding from '%s'");

  /**
   * 7.1 Instance Methods: It is a static warning if an instance method <i>m1</i> overrides an
   * instance method <i>m2</i> and the type of <i>m1</i> is not a subtype of the type of <i>m2</i>.
   *
   * @param actualParamTypeName the name of the expected parameter type
   * @param expectedParamType the name of the actual parameter type, not assignable to the
   *          actualParamTypeName
   * @param className the name of the class where the overridden method is declared
   */
  static final StaticWarningCode INVALID_METHOD_OVERRIDE_NAMED_PARAM_TYPE = new StaticWarningCode('INVALID_METHOD_OVERRIDE_NAMED_PARAM_TYPE', 27, "The parameter type '%s' is not assignable to '%s' as required from method it is overriding from '%s'");

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
  static final StaticWarningCode INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE = new StaticWarningCode('INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE', 28, "The parameter type '%s' is not assignable to '%s' as required by the method it is overriding from '%s'");

  /**
   * 7.1 Instance Methods: It is a static warning if an instance method <i>m1</i> overrides an
   * instance method <i>m2</i> and the type of <i>m1</i> is not a subtype of the type of <i>m2</i>.
   *
   * @param actualParamTypeName the name of the expected parameter type
   * @param expectedParamType the name of the actual parameter type, not assignable to the
   *          actualParamTypeName
   * @param className the name of the class where the overridden method is declared
   */
  static final StaticWarningCode INVALID_METHOD_OVERRIDE_OPTIONAL_PARAM_TYPE = new StaticWarningCode('INVALID_METHOD_OVERRIDE_OPTIONAL_PARAM_TYPE', 29, "The parameter type '%s' is not assignable to '%s' as required from method it is overriding from '%s'");

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
  static final StaticWarningCode INVALID_METHOD_OVERRIDE_RETURN_TYPE = new StaticWarningCode('INVALID_METHOD_OVERRIDE_RETURN_TYPE', 30, "The return type '%s' is not assignable to '%s' as required from method it is overriding from '%s'");

  /**
   * 7.1 Instance Methods: It is a static warning if an instance method <i>m1</i> overrides an
   * instance member <i>m2</i>, the signature of <i>m2</i> explicitly specifies a default value for
   * a formal parameter <i>p</i> and the signature of <i>m1</i> specifies a different default value
   * for <i>p</i>.
   */
  static final StaticWarningCode INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED = new StaticWarningCode('INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED', 31, "Parameters cannot override default values, this method overrides '%s.%s' where '%s' has a different value");

  /**
   * 7.1 Instance Methods: It is a static warning if an instance method <i>m1</i> overrides an
   * instance member <i>m2</i>, the signature of <i>m2</i> explicitly specifies a default value for
   * a formal parameter <i>p</i> and the signature of <i>m1</i> specifies a different default value
   * for <i>p</i>.
   */
  static final StaticWarningCode INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL = new StaticWarningCode('INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL', 32, "Parameters cannot override default values, this method overrides '%s.%s' where this positional parameter has a different value");

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
  static final StaticWarningCode INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE = new StaticWarningCode('INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE', 33, "The parameter type '%s' is not assignable to '%s' as required by the setter it is overriding from '%s'");

  /**
   * 12.15.4 Super Invocation: A super method invocation <i>i</i> has the form
   * <i>super.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;
   * x<sub>n+k</sub>: a<sub>n+k</sub>)</i>. If <i>S.m</i> exists, it is a static warning if the type
   * <i>F</i> of <i>S.m</i> may not be assigned to a function type.
   */
  static final StaticWarningCode INVOCATION_OF_NON_FUNCTION = new StaticWarningCode('INVOCATION_OF_NON_FUNCTION', 34, "");

  /**
   * 7.3 Setters: It is a static warning if a class has a setter named <i>v=</i> with argument type
   * <i>T</i> and a getter named <i>v</i> with return type <i>S</i>, and <i>T</i> may not be
   * assigned to <i>S</i>.
   */
  static final StaticWarningCode MISMATCHED_GETTER_AND_SETTER_TYPES = new StaticWarningCode('MISMATCHED_GETTER_AND_SETTER_TYPES', 35, "The parameter type for setter '%s' is %s which is not assignable to its getter (of type %s)");

  /**
   * 12.11.1 New: It is a static warning if <i>q</i> is a constructor of an abstract class and
   * <i>q</i> is not a factory constructor.
   */
  static final StaticWarningCode NEW_WITH_ABSTRACT_CLASS = new StaticWarningCode('NEW_WITH_ABSTRACT_CLASS', 36, "Abstract classes cannot be created with a 'new' expression");

  /**
   * 12.11.1 New: It is a static warning if <i>T</i> is not a class accessible in the current scope,
   * optionally followed by type arguments.
   *
   * @param name the name of the non-type element
   */
  static final StaticWarningCode NEW_WITH_NON_TYPE = new StaticWarningCode('NEW_WITH_NON_TYPE', 37, "The name '%s' is not a class");

  /**
   * 12.11.1 New: If <i>T</i> is a class or parameterized type accessible in the current scope then:
   * 1. If <i>e</i> is of the form <i>new T.id(a<sub>1</sub>, &hellip;, a<sub>n</sub>,
   * x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;, x<sub>n+k</sub>: a<sub>n+k</sub>)</i> it is a
   * static warning if <i>T.id</i> is not the name of a constructor declared by the type <i>T</i>.
   * If <i>e</i> of the form <i>new T(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>:
   * a<sub>n+1</sub>, &hellip; x<sub>n+k</sub>: a<sub>n+kM/sub>)</i> it is a static warning if the
   * type <i>T</i> does not declare a constructor with the same name as the declaration of <i>T</i>.
   */
  static final StaticWarningCode NEW_WITH_UNDEFINED_CONSTRUCTOR = new StaticWarningCode('NEW_WITH_UNDEFINED_CONSTRUCTOR', 38, "The class '%s' does not have a constructor '%s'");

  /**
   * 12.11.1 New: If <i>T</i> is a class or parameterized type accessible in the current scope then:
   * 1. If <i>e</i> is of the form <i>new T.id(a<sub>1</sub>, &hellip;, a<sub>n</sub>,
   * x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;, x<sub>n+k</sub>: a<sub>n+k</sub>)</i> it is a
   * static warning if <i>T.id</i> is not the name of a constructor declared by the type <i>T</i>.
   * If <i>e</i> of the form <i>new T(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>:
   * a<sub>n+1</sub>, &hellip; x<sub>n+k</sub>: a<sub>n+kM/sub>)</i> it is a static warning if the
   * type <i>T</i> does not declare a constructor with the same name as the declaration of <i>T</i>.
   */
  static final StaticWarningCode NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT = new StaticWarningCode('NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT', 39, "The class '%s' does not have a default constructor");

  /**
   * 7.9.1 Inheritance and Overriding: It is a static warning if a non-abstract class inherits an
   * abstract method.
   *
   * 7.10 Superinterfaces: It is a static warning if the implicit interface of a non-abstract class
   * <i>C</i> includes an instance member <i>m</i> and <i>C</i> does not declare or inherit a
   * corresponding instance member <i>m</i>.
   *
   * @param memberName the name of the first member
   * @param memberName the name of the second member
   * @param memberName the name of the third member
   * @param memberName the name of the fourth member
   * @param additionalCount the number of additional missing members that aren't listed
   */
  static final StaticWarningCode NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS = new StaticWarningCode('NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS', 40, "Missing inherited members: '%s', '%s', '%s', '%s' and %d more");

  /**
   * 7.9.1 Inheritance and Overriding: It is a static warning if a non-abstract class inherits an
   * abstract method.
   *
   * 7.10 Superinterfaces: It is a static warning if the implicit interface of a non-abstract class
   * <i>C</i> includes an instance member <i>m</i> and <i>C</i> does not declare or inherit a
   * corresponding instance member <i>m</i>.
   *
   * @param memberName the name of the first member
   * @param memberName the name of the second member
   * @param memberName the name of the third member
   * @param memberName the name of the fourth member
   */
  static final StaticWarningCode NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR = new StaticWarningCode('NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR', 41, "Missing inherited members: '%s', '%s', '%s' and '%s'");

  /**
   * 7.9.1 Inheritance and Overriding: It is a static warning if a non-abstract class inherits an
   * abstract method.
   *
   * 7.10 Superinterfaces: It is a static warning if the implicit interface of a non-abstract class
   * <i>C</i> includes an instance member <i>m</i> and <i>C</i> does not declare or inherit a
   * corresponding instance member <i>m</i>.
   *
   * @param memberName the name of the member
   */
  static final StaticWarningCode NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE = new StaticWarningCode('NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE', 42, "Missing inherited member '%s'");

  /**
   * 7.9.1 Inheritance and Overriding: It is a static warning if a non-abstract class inherits an
   * abstract method.
   *
   * 7.10 Superinterfaces: It is a static warning if the implicit interface of a non-abstract class
   * <i>C</i> includes an instance member <i>m</i> and <i>C</i> does not declare or inherit a
   * corresponding instance member <i>m</i>.
   *
   * @param memberName the name of the first member
   * @param memberName the name of the second member
   * @param memberName the name of the third member
   */
  static final StaticWarningCode NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE = new StaticWarningCode('NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE', 43, "Missing inherited members: '%s', '%s' and '%s'");

  /**
   * 7.9.1 Inheritance and Overriding: It is a static warning if a non-abstract class inherits an
   * abstract method.
   *
   * 7.10 Superinterfaces: It is a static warning if the implicit interface of a non-abstract class
   * <i>C</i> includes an instance member <i>m</i> and <i>C</i> does not declare or inherit a
   * corresponding instance member <i>m</i>.
   *
   * @param memberName the name of the first member
   * @param memberName the name of the second member
   */
  static final StaticWarningCode NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO = new StaticWarningCode('NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO', 44, "Missing inherited members: '%s' and '%s'");

  /**
   * 13.11 Try: An on-catch clause of the form <i>on T catch (p<sub>1</sub>, p<sub>2</sub>) s</i> or
   * <i>on T s</i> matches an object <i>o</i> if the type of <i>o</i> is a subtype of <i>T</i>. It
   * is a static warning if <i>T</i> does not denote a type available in the lexical scope of the
   * catch clause.
   *
   * @param name the name of the non-type element
   */
  static final StaticWarningCode NON_TYPE_IN_CATCH_CLAUSE = new StaticWarningCode('NON_TYPE_IN_CATCH_CLAUSE', 45, "The name '%s' is not a type and cannot be used in an on-catch clause");

  /**
   * 7.1.1 Operators: It is a static warning if the return type of the user-declared operator []= is
   * explicitly declared and not void.
   */
  static final StaticWarningCode NON_VOID_RETURN_FOR_OPERATOR = new StaticWarningCode('NON_VOID_RETURN_FOR_OPERATOR', 46, "The return type of the operator []= must be 'void'");

  /**
   * 7.3 Setters: It is a static warning if a setter declares a return type other than void.
   */
  static final StaticWarningCode NON_VOID_RETURN_FOR_SETTER = new StaticWarningCode('NON_VOID_RETURN_FOR_SETTER', 47, "The return type of the setter must be 'void'");

  /**
   * 15.1 Static Types: A type <i>T</i> is malformed iff: * <i>T</i> has the form <i>id</i> or the
   * form <i>prefix.id</i>, and in the enclosing lexical scope, the name <i>id</i> (respectively
   * <i>prefix.id</i>) does not denote a type. * <i>T</i> denotes a type variable in the
   * enclosing lexical scope, but occurs in the signature or body of a static member. *
   * <i>T</i> is a parameterized type of the form <i>G&lt;S<sub>1</sub>, .., S<sub>n</sub>&gt;</i>,
   * and <i>G</i> is malformed.
   *
   * Any use of a malformed type gives rise to a static warning.
   *
   * @param nonTypeName the name that is not a type
   */
  static final StaticWarningCode NOT_A_TYPE = new StaticWarningCode('NOT_A_TYPE', 48, "%s is not a type");

  /**
   * 12.14.2 Binding Actuals to Formals: It is a static warning if <i>m &lt; h</i> or if <i>m &gt;
   * n</i>.
   *
   * @param requiredCount the expected number of required arguments
   * @param argumentCount the actual number of positional arguments given
   * @see #EXTRA_POSITIONAL_ARGUMENTS
   */
  static final StaticWarningCode NOT_ENOUGH_REQUIRED_ARGUMENTS = new StaticWarningCode('NOT_ENOUGH_REQUIRED_ARGUMENTS', 49, "%d required argument(s) expected, but %d found");

  /**
   * 14.3 Parts: It is a static warning if the referenced part declaration <i>p</i> names a library
   * other than the current library as the library to which <i>p</i> belongs.
   *
   * @param expectedLibraryName the name of expected library name
   * @param actualLibraryName the non-matching actual library name from the "part of" declaration
   */
  static final StaticWarningCode PART_OF_DIFFERENT_LIBRARY = new StaticWarningCode('PART_OF_DIFFERENT_LIBRARY', 50, "Expected this library to be part of '%s', not '%s'");

  /**
   * 7.6.2 Factories: It is a static warning if the function type of <i>k'</i> is not a subtype of
   * the type of <i>k</i>.
   *
   * @param redirectedName the name of the redirected constructor
   * @param redirectingName the name of the redirecting constructor
   */
  static final StaticWarningCode REDIRECT_TO_INVALID_FUNCTION_TYPE = new StaticWarningCode('REDIRECT_TO_INVALID_FUNCTION_TYPE', 51, "The redirected constructor '%s' has incompatible parameters with '%s'");

  /**
   * 7.6.2 Factories: It is a static warning if the function type of <i>k'</i> is not a subtype of
   * the type of <i>k</i>.
   *
   * @param redirectedName the name of the redirected constructor return type
   * @param redirectingName the name of the redirecting constructor return type
   */
  static final StaticWarningCode REDIRECT_TO_INVALID_RETURN_TYPE = new StaticWarningCode('REDIRECT_TO_INVALID_RETURN_TYPE', 52, "The return type '%s' of the redirected constructor is not a subclass of '%s'");

  /**
   * 7.6.2 Factories: It is a static warning if type does not denote a class accessible in the
   * current scope; if type does denote such a class <i>C</i> it is a static warning if the
   * referenced constructor (be it <i>type</i> or <i>type.id</i>) is not a constructor of <i>C</i>.
   */
  static final StaticWarningCode REDIRECT_TO_MISSING_CONSTRUCTOR = new StaticWarningCode('REDIRECT_TO_MISSING_CONSTRUCTOR', 53, "The constructor '%s' could not be found in '%s'");

  /**
   * 7.6.2 Factories: It is a static warning if type does not denote a class accessible in the
   * current scope; if type does denote such a class <i>C</i> it is a static warning if the
   * referenced constructor (be it <i>type</i> or <i>type.id</i>) is not a constructor of <i>C</i>.
   */
  static final StaticWarningCode REDIRECT_TO_NON_CLASS = new StaticWarningCode('REDIRECT_TO_NON_CLASS', 54, "The name '%s' is not a type and cannot be used in a redirected constructor");

  /**
   * 13.11 Return: Let <i>f</i> be the function immediately enclosing a return statement of the form
   * <i>return;</i> It is a static warning if both of the following conditions hold:
   * <ol>
   * * <i>f</i> is not a generative constructor.
   * * The return type of <i>f</i> may not be assigned to void.
   * </ol>
   */
  static final StaticWarningCode RETURN_WITHOUT_VALUE = new StaticWarningCode('RETURN_WITHOUT_VALUE', 55, "Missing return value after 'return'");

  /**
   * 12.15.3 Static Invocation: It is a static warning if <i>C</i> does not declare a static method
   * or getter <i>m</i>.
   *
   * @param memberName the name of the instance member
   */
  static final StaticWarningCode STATIC_ACCESS_TO_INSTANCE_MEMBER = new StaticWarningCode('STATIC_ACCESS_TO_INSTANCE_MEMBER', 56, "Instance member '%s' cannot be accessed using static access");

  /**
   * 13.9 Switch: It is a static warning if the type of <i>e</i> may not be assigned to the type of
   * <i>e<sub>k</sub></i>.
   */
  static final StaticWarningCode SWITCH_EXPRESSION_NOT_ASSIGNABLE = new StaticWarningCode('SWITCH_EXPRESSION_NOT_ASSIGNABLE', 57, "Type '%s' of the switch expression is not assignable to the type '%s' of case expressions");

  /**
   * 12.31 Type Test: It is a static warning if <i>T</i> does not denote a type available in the
   * current lexical scope.
   */
  static final StaticWarningCode TYPE_TEST_NON_TYPE = new StaticWarningCode('TYPE_TEST_NON_TYPE', 58, "The name '%s' is not a type and cannot be used in an 'is' expression");

  /**
   * 10 Generics: However, a type parameter is considered to be a malformed type when referenced by
   * a static member.
   *
   * 15.1 Static Types: Any use of a malformed type gives rise to a static warning. A malformed type
   * is then interpreted as dynamic by the static type checker and the runtime.
   */
  static final StaticWarningCode TYPE_PARAMETER_REFERENCED_BY_STATIC = new StaticWarningCode('TYPE_PARAMETER_REFERENCED_BY_STATIC', 59, "Static members cannot reference type parameters");

  /**
   * 15.1 Static Types: A type <i>T</i> is malformed iff: * <i>T</i> has the form <i>id</i> or the
   * form <i>prefix.id</i>, and in the enclosing lexical scope, the name <i>id</i> (respectively
   * <i>prefix.id</i>) does not denote a type. * <i>T</i> denotes a type variable in the
   * enclosing lexical scope, but occurs in the signature or body of a static member. *
   * <i>T</i> is a parameterized type of the form <i>G&lt;S<sub>1</sub>, .., S<sub>n</sub>&gt;</i>,
   * and <i>G</i> is malformed.
   *
   * Any use of a malformed type gives rise to a static warning.
   */
  static final StaticWarningCode TYPE_VARIABLE_IN_STATIC_SCOPE = new StaticWarningCode('TYPE_VARIABLE_IN_STATIC_SCOPE', 60, "");

  /**
   * 12.15.3 Static Invocation: A static method invocation <i>i</i> has the form
   * <i>C.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;
   * x<sub>n+k</sub>: a<sub>n+k</sub>)</i>. It is a static warning if <i>C</i> does not denote a
   * class in the current scope.
   *
   * @param undefinedClassName the name of the undefined class
   */
  static final StaticWarningCode UNDEFINED_CLASS = new StaticWarningCode('UNDEFINED_CLASS', 61, "Undefined class '%s'");

  /**
   * Same as [UNDEFINED_CLASS], but to catch using "boolean" instead of "bool".
   */
  static final StaticWarningCode UNDEFINED_CLASS_BOOLEAN = new StaticWarningCode('UNDEFINED_CLASS_BOOLEAN', 62, "Undefined class 'boolean'; did you mean 'bool'?");

  /**
   * 12.17 Getter Invocation: It is a static warning if there is no class <i>C</i> in the enclosing
   * lexical scope of <i>i</i>, or if <i>C</i> does not declare, implicitly or explicitly, a getter
   * named <i>m</i>.
   *
   * @param getterName the name of the getter
   * @param enclosingType the name of the enclosing type where the getter is being looked for
   */
  static final StaticWarningCode UNDEFINED_GETTER = new StaticWarningCode('UNDEFINED_GETTER', 63, "There is no such getter '%s' in '%s'");

  /**
   * 12.30 Identifier Reference: It is as static warning if an identifier expression of the form
   * <i>id</i> occurs inside a top level or static function (be it function, method, getter, or
   * setter) or variable initializer and there is no declaration <i>d</i> with name <i>id</i> in the
   * lexical scope enclosing the expression.
   */
  static final StaticWarningCode UNDEFINED_IDENTIFIER = new StaticWarningCode('UNDEFINED_IDENTIFIER', 64, "Undefined name '%s'");

  /**
   * 12.14.2 Binding Actuals to Formals: Furthermore, each <i>q<sub>i</sub></i>, <i>1<=i<=l</i>,
   * must have a corresponding named parameter in the set {<i>p<sub>n+1</sub></i> ...
   * <i>p<sub>n+k</sub></i>} or a static warning occurs.
   *
   * @param name the name of the requested named parameter
   */
  static final StaticWarningCode UNDEFINED_NAMED_PARAMETER = new StaticWarningCode('UNDEFINED_NAMED_PARAMETER', 65, "The named parameter '%s' is not defined");

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
  static final StaticWarningCode UNDEFINED_SETTER = new StaticWarningCode('UNDEFINED_SETTER', 66, "There is no such setter '%s' in '%s'");

  /**
   * 12.15.3 Static Invocation: It is a static warning if <i>C</i> does not declare a static method
   * or getter <i>m</i>.
   *
   * @param methodName the name of the method
   * @param enclosingType the name of the enclosing type where the method is being looked for
   */
  static final StaticWarningCode UNDEFINED_STATIC_METHOD_OR_GETTER = new StaticWarningCode('UNDEFINED_STATIC_METHOD_OR_GETTER', 67, "There is no such static method '%s' in '%s'");
  static final List<StaticWarningCode> values = [AMBIGUOUS_IMPORT, ARGUMENT_TYPE_NOT_ASSIGNABLE, ASSIGNMENT_TO_FINAL, CASE_BLOCK_NOT_TERMINATED, CAST_TO_NON_TYPE, COMMENT_REFERENCE_CONSTRUCTOR_NOT_VISIBLE, COMMENT_REFERENCE_IDENTIFIER_NOT_VISIBLE, COMMENT_REFERENCE_UNDECLARED_CONSTRUCTOR, COMMENT_REFERENCE_UNDECLARED_IDENTIFIER, COMMENT_REFERENCE_URI_NOT_LIBRARY, CONCRETE_CLASS_WITH_ABSTRACT_MEMBER, CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER, CONFLICTING_INSTANCE_SETTER_AND_SUPERCLASS_MEMBER, CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER, CONFLICTING_STATIC_SETTER_AND_INSTANCE_MEMBER, CONST_WITH_ABSTRACT_CLASS, EQUAL_KEYS_IN_MAP, EXPORT_DUPLICATED_LIBRARY_NAME, EXTRA_POSITIONAL_ARGUMENTS, FIELD_INITIALIZER_NOT_ASSIGNABLE, FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE, FINAL_NOT_INITIALIZED, IMPORT_DUPLICATED_LIBRARY_NAME, INCONSISTENT_METHOD_INHERITANCE_GETTER_AND_METHOD, INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC, INVALID_FACTORY_NAME, INVALID_GETTER_OVERRIDE_RETURN_TYPE, INVALID_METHOD_OVERRIDE_NAMED_PARAM_TYPE, INVALID_METHOD_OVERRIDE_NORMAL_PARAM_TYPE, INVALID_METHOD_OVERRIDE_OPTIONAL_PARAM_TYPE, INVALID_METHOD_OVERRIDE_RETURN_TYPE, INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED, INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL, INVALID_SETTER_OVERRIDE_NORMAL_PARAM_TYPE, INVOCATION_OF_NON_FUNCTION, MISMATCHED_GETTER_AND_SETTER_TYPES, NEW_WITH_ABSTRACT_CLASS, NEW_WITH_NON_TYPE, NEW_WITH_UNDEFINED_CONSTRUCTOR, NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT, NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS, NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR, NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE, NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE, NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO, NON_TYPE_IN_CATCH_CLAUSE, NON_VOID_RETURN_FOR_OPERATOR, NON_VOID_RETURN_FOR_SETTER, NOT_A_TYPE, NOT_ENOUGH_REQUIRED_ARGUMENTS, PART_OF_DIFFERENT_LIBRARY, REDIRECT_TO_INVALID_FUNCTION_TYPE, REDIRECT_TO_INVALID_RETURN_TYPE, REDIRECT_TO_MISSING_CONSTRUCTOR, REDIRECT_TO_NON_CLASS, RETURN_WITHOUT_VALUE, STATIC_ACCESS_TO_INSTANCE_MEMBER, SWITCH_EXPRESSION_NOT_ASSIGNABLE, TYPE_TEST_NON_TYPE, TYPE_PARAMETER_REFERENCED_BY_STATIC, TYPE_VARIABLE_IN_STATIC_SCOPE, UNDEFINED_CLASS, UNDEFINED_CLASS_BOOLEAN, UNDEFINED_GETTER, UNDEFINED_IDENTIFIER, UNDEFINED_NAMED_PARAMETER, UNDEFINED_SETTER, UNDEFINED_STATIC_METHOD_OR_GETTER];

  /// The name of this enum constant, as declared in the enum declaration.
  final String name;

  /// The position in the enum declaration.
  final int ordinal;

  /**
   * The message template used to create the message to be displayed for this error.
   */
  String _message;

  /**
   * Initialize a newly created error code to have the given type and message.
   *
   * @param message the message template used to create the message to be displayed for the error
   */
  StaticWarningCode(this.name, this.ordinal, String message) {
    this._message = message;
  }
  ErrorSeverity get errorSeverity => ErrorType.STATIC_WARNING.severity;
  String get message => _message;
  ErrorType get type => ErrorType.STATIC_WARNING;
  int compareTo(StaticWarningCode other) => ordinal - other.ordinal;
  int get hashCode => ordinal;
  String toString() => name;
}
/**
 * The interface `AnalysisErrorListener` defines the behavior of objects that listen for
 * [AnalysisError] being produced by the analysis engine.
 *
 * @coverage dart.engine.error
 */
abstract class AnalysisErrorListener {

  /**
   * An error listener that ignores errors that are reported to it.
   */
  static final AnalysisErrorListener _NULL_LISTENER = new AnalysisErrorListener_5();

  /**
   * This method is invoked when an error has been found by the analysis engine.
   *
   * @param error the error that was just found (not `null`)
   */
  void onError(AnalysisError error);
}
class AnalysisErrorListener_5 implements AnalysisErrorListener {
  void onError(AnalysisError event) {
  }
}
/**
 * The enumeration `HtmlWarningCode` defines the error codes used for warnings in HTML files.
 * The convention for this class is for the name of the error code to indicate the problem that
 * caused the error to be generated and for the error message to explain what is wrong and, when
 * appropriate, how the problem can be corrected.
 *
 * @coverage dart.engine.error
 */
class HtmlWarningCode implements Comparable<HtmlWarningCode>, ErrorCode {

  /**
   * An error code indicating that the value of the 'src' attribute of a Dart script tag is not a
   * valid URI.
   *
   * @param uri the URI that is invalid
   */
  static final HtmlWarningCode INVALID_URI = new HtmlWarningCode('INVALID_URI', 0, "Invalid URI syntax: '%s'");

  /**
   * An error code indicating that the value of the 'src' attribute of a Dart script tag references
   * a file that does not exist.
   *
   * @param uri the URI pointing to a non-existent file
   */
  static final HtmlWarningCode URI_DOES_NOT_EXIST = new HtmlWarningCode('URI_DOES_NOT_EXIST', 1, "Target of URI does not exist: '%s'");
  static final List<HtmlWarningCode> values = [INVALID_URI, URI_DOES_NOT_EXIST];

  /// The name of this enum constant, as declared in the enum declaration.
  final String name;

  /// The position in the enum declaration.
  final int ordinal;

  /**
   * The message template used to create the message to be displayed for this error.
   */
  String _message;

  /**
   * Initialize a newly created error code to have the given type and message.
   *
   * @param message the message template used to create the message to be displayed for the error
   */
  HtmlWarningCode(this.name, this.ordinal, String message) {
    this._message = message;
  }
  ErrorSeverity get errorSeverity => ErrorSeverity.WARNING;
  String get message => _message;
  ErrorType get type => ErrorType.STATIC_WARNING;
  int compareTo(HtmlWarningCode other) => ordinal - other.ordinal;
  int get hashCode => ordinal;
  String toString() => name;
}
/**
 * The enumeration `StaticTypeWarningCode` defines the error codes used for static type
 * warnings. The convention for this class is for the name of the error code to indicate the problem
 * that caused the error to be generated and for the error message to explain what is wrong and,
 * when appropriate, how the problem can be corrected.
 *
 * @coverage dart.engine.error
 */
class StaticTypeWarningCode implements Comparable<StaticTypeWarningCode>, ErrorCode {

  /**
   * 12.18 Assignment: Let <i>T</i> be the static type of <i>e<sub>1</sub></i>. It is a static type
   * warning if <i>T</i> does not have an accessible instance setter named <i>v=</i>.
   *
   * @see #UNDEFINED_SETTER
   */
  static final StaticTypeWarningCode INACCESSIBLE_SETTER = new StaticTypeWarningCode('INACCESSIBLE_SETTER', 0, "");

  /**
   * 8.1.1 Inheritance and Overriding: However, if there are multiple members <i>m<sub>1</sub>,
   * &hellip; m<sub>k</sub></i> with the same name <i>n</i> that would be inherited (because
   * identically named members existed in several superinterfaces) then at most one member is
   * inherited.
   *
   * If the static types <i>T<sub>1</sub>, &hellip;, T<sub>k</sub></i> of the members
   * <i>m<sub>1</sub>, &hellip;, m<sub>k</sub></i> are not identical, then there must be a member
   * <i>m<sub>x</sub></i> such that <i>T<sub>x</sub> &lt; T<sub>i</sub>, 1 &lt;= x &lt;= k</i> for
   * all <i>i, 1 &lt;= i &lt; k</i>, or a static type warning occurs. The member that is inherited
   * is <i>m<sub>x</sub></i>, if it exists; otherwise:
   * <ol>
   * * If all of <i>m<sub>1</sub>, &hellip; m<sub>k</sub></i> have the same number <i>r</i> of
   * required parameters and the same set of named parameters <i>s</i>, then let <i>h = max(
   * numberOfOptionalPositionals( m<sub>i</sub> ) ), 1 &lt;= i &lt;= k</i>. <i>I</i> has a method
   * named <i>n</i>, with <i>r</i> required parameters of type dynamic, <i>h</i> optional positional
   * parameters of type dynamic, named parameters <i>s</i> of type dynamic and return type dynamic.
   * * Otherwise none of the members <i>m<sub>1</sub>, &hellip;, m<sub>k</sub></i> is inherited.
   * </ol>
   */
  static final StaticTypeWarningCode INCONSISTENT_METHOD_INHERITANCE = new StaticTypeWarningCode('INCONSISTENT_METHOD_INHERITANCE', 1, "'%s' is inherited by at least two interfaces inconsistently");

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
  static final StaticTypeWarningCode INVALID_ASSIGNMENT = new StaticTypeWarningCode('INVALID_ASSIGNMENT', 2, "A value of type '%s' cannot be assigned to a variable of type '%s'");

  /**
   * 12.14.4 Function Expression Invocation: A function expression invocation <i>i</i> has the form
   * <i>e<sub>f</sub>(a<sub>1</sub>, &hellip; a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>,
   * &hellip;, x<sub>n+k</sub>: a<sub>n+k</sub>)</i>, where <i>e<sub>f</sub></i> is an expression.
   *
   * It is a static type warning if the static type <i>F</i> of <i>e<sub>f</sub></i> may not be
   * assigned to a function type.
   *
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
   * @param nonFunctionIdentifier the name of the identifier that is not a function type
   */
  static final StaticTypeWarningCode INVOCATION_OF_NON_FUNCTION = new StaticTypeWarningCode('INVOCATION_OF_NON_FUNCTION', 3, "'%s' is not a method");

  /**
   * 12.19 Conditional: It is a static type warning if the type of <i>e<sub>1</sub></i> may not be
   * assigned to bool.
   *
   * 13.5 If: It is a static type warning if the type of the expression <i>b</i> may not be assigned
   * to bool.
   *
   * 13.7 While: It is a static type warning if the type of <i>e</i> may not be assigned to bool.
   *
   * 13.8 Do: It is a static type warning if the type of <i>e</i> cannot be assigned to bool.
   */
  static final StaticTypeWarningCode NON_BOOL_CONDITION = new StaticTypeWarningCode('NON_BOOL_CONDITION', 4, "Conditions must have a static type of 'bool'");

  /**
   * 13.15 Assert: It is a static type warning if the type of <i>e</i> may not be assigned to either
   * bool or () &rarr; bool
   */
  static final StaticTypeWarningCode NON_BOOL_EXPRESSION = new StaticTypeWarningCode('NON_BOOL_EXPRESSION', 5, "Assertions must be on either a 'bool' or '() -> bool'");

  /**
   * 15.8 Parameterized Types: It is a static type warning if <i>A<sub>i</sub>, 1 &lt;= i &lt;=
   * n</i> does not denote a type in the enclosing lexical scope.
   */
  static final StaticTypeWarningCode NON_TYPE_AS_TYPE_ARGUMENT = new StaticTypeWarningCode('NON_TYPE_AS_TYPE_ARGUMENT', 6, "The name '%s' is not a type and cannot be used as a parameterized type");

  /**
   * 7.6.2 Factories: It is a static type warning if any of the type arguments to <i>k'</i> are not
   * subtypes of the bounds of the corresponding formal type parameters of type.
   */
  static final StaticTypeWarningCode REDIRECT_WITH_INVALID_TYPE_PARAMETERS = new StaticTypeWarningCode('REDIRECT_WITH_INVALID_TYPE_PARAMETERS', 7, "");

  /**
   * 13.11 Return: It is a static type warning if the type of <i>e</i> may not be assigned to the
   * declared return type of the immediately enclosing function.
   *
   * @param actualReturnType the return type as declared in the return statement
   * @param expectedReturnType the expected return type as defined by the method
   * @param methodName the name of the method
   */
  static final StaticTypeWarningCode RETURN_OF_INVALID_TYPE = new StaticTypeWarningCode('RETURN_OF_INVALID_TYPE', 8, "The return type '%s' is not a '%s', as defined by the method '%s'");

  /**
   * 12.11 Instance Creation: It is a static type warning if any of the type arguments to a
   * constructor of a generic type <i>G</i> invoked by a new expression or a constant object
   * expression are not subtypes of the bounds of the corresponding formal type parameters of
   * <i>G</i>.
   *
   * 10 Generics: It is a static type warning if a type parameter is a supertype of its upper bound.
   *
   * 15.8 Parameterized Types: If <i>S</i> is the static type of a member <i>m</i> of <i>G</i>, then
   * the static type of the member <i>m</i> of <i>G&lt;A<sub>1</sub>, &hellip; A<sub>n</sub>&gt;</i>
   * is <i>[A<sub>1</sub>, &hellip;, A<sub>n</sub>/T<sub>1</sub>, &hellip;, T<sub>n</sub>]S</i>
   * where <i>T<sub>1</sub>, &hellip; T<sub>n</sub></i> are the formal type parameters of <i>G</i>.
   * Let <i>B<sub>i</sub></i> be the bounds of <i>T<sub>i</sub>, 1 &lt;= i &lt;= n</i>. It is a
   * static type warning if <i>A<sub>i</sub></i> is not a subtype of <i>[A<sub>1</sub>, &hellip;,
   * A<sub>n</sub>/T<sub>1</sub>, &hellip;, T<sub>n</sub>]B<sub>i</sub>, 1 &lt;= i &lt;= n</i>.
   *
   * @param boundedTypeName the name of the type used in the instance creation that should be
   *          limited by the bound as specified in the class declaration
   * @param boundingTypeName the name of the bounding type
   */
  static final StaticTypeWarningCode TYPE_ARGUMENT_NOT_MATCHING_BOUNDS = new StaticTypeWarningCode('TYPE_ARGUMENT_NOT_MATCHING_BOUNDS', 9, "'%s' does not extend '%s'");

  /**
   * Specification reference needed. This is equivalent to [UNDEFINED_METHOD], but for
   * top-level functions.
   *
   * @param methodName the name of the method that is undefined
   */
  static final StaticTypeWarningCode UNDEFINED_FUNCTION = new StaticTypeWarningCode('UNDEFINED_FUNCTION', 10, "The function '%s' is not defined");

  /**
   * 12.17 Getter Invocation: Let <i>T</i> be the static type of <i>e</i>. It is a static type
   * warning if <i>T</i> does not have a getter named <i>m</i>.
   *
   * @param getterName the name of the getter
   * @param enclosingType the name of the enclosing type where the getter is being looked for
   */
  static final StaticTypeWarningCode UNDEFINED_GETTER = new StaticTypeWarningCode('UNDEFINED_GETTER', 11, "There is no such getter '%s' in '%s'");

  /**
   * 12.15.1 Ordinary Invocation: Let <i>T</i> be the static type of <i>o</i>. It is a static type
   * warning if <i>T</i> does not have an accessible instance member named <i>m</i>.
   *
   * @param methodName the name of the method that is undefined
   * @param typeName the resolved type name that the method lookup is happening on
   */
  static final StaticTypeWarningCode UNDEFINED_METHOD = new StaticTypeWarningCode('UNDEFINED_METHOD', 12, "The method '%s' is not defined for the class '%s'");

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
  static final StaticTypeWarningCode UNDEFINED_OPERATOR = new StaticTypeWarningCode('UNDEFINED_OPERATOR', 13, "There is no such operator '%s' in '%s'");

  /**
   * 12.18 Assignment: Let <i>T</i> be the static type of <i>e<sub>1</sub></i>. It is a static type
   * warning if <i>T</i> does not have an accessible instance setter named <i>v=</i>.
   *
   * @param setterName the name of the setter
   * @param enclosingType the name of the enclosing type where the setter is being looked for
   * @see #INACCESSIBLE_SETTER
   */
  static final StaticTypeWarningCode UNDEFINED_SETTER = new StaticTypeWarningCode('UNDEFINED_SETTER', 14, "There is no such setter '%s' in '%s'");

  /**
   * 12.15.4 Super Invocation: A super method invocation <i>i</i> has the form
   * <i>super.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;
   * x<sub>n+k</sub>: a<sub>n+k</sub>)</i>. It is a static type warning if <i>S</i> does not have an
   * accessible instance member named <i>m</i>.
   *
   * @param methodName the name of the method that is undefined
   * @param typeName the resolved type name that the method lookup is happening on
   */
  static final StaticTypeWarningCode UNDEFINED_SUPER_METHOD = new StaticTypeWarningCode('UNDEFINED_SUPER_METHOD', 15, "There is no such method '%s' in '%s'");

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
  static final StaticTypeWarningCode WRONG_NUMBER_OF_TYPE_ARGUMENTS = new StaticTypeWarningCode('WRONG_NUMBER_OF_TYPE_ARGUMENTS', 16, "The type '%s' is declared with %d type parameters, but %d type arguments were given");
  static final List<StaticTypeWarningCode> values = [INACCESSIBLE_SETTER, INCONSISTENT_METHOD_INHERITANCE, INVALID_ASSIGNMENT, INVOCATION_OF_NON_FUNCTION, NON_BOOL_CONDITION, NON_BOOL_EXPRESSION, NON_TYPE_AS_TYPE_ARGUMENT, REDIRECT_WITH_INVALID_TYPE_PARAMETERS, RETURN_OF_INVALID_TYPE, TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, UNDEFINED_FUNCTION, UNDEFINED_GETTER, UNDEFINED_METHOD, UNDEFINED_OPERATOR, UNDEFINED_SETTER, UNDEFINED_SUPER_METHOD, WRONG_NUMBER_OF_TYPE_ARGUMENTS];

  /// The name of this enum constant, as declared in the enum declaration.
  final String name;

  /// The position in the enum declaration.
  final int ordinal;

  /**
   * The message template used to create the message to be displayed for this error.
   */
  String _message;

  /**
   * Initialize a newly created error code to have the given type and message.
   *
   * @param message the message template used to create the message to be displayed for the error
   */
  StaticTypeWarningCode(this.name, this.ordinal, String message) {
    this._message = message;
  }
  ErrorSeverity get errorSeverity => ErrorType.STATIC_TYPE_WARNING.severity;
  String get message => _message;
  ErrorType get type => ErrorType.STATIC_TYPE_WARNING;
  int compareTo(StaticTypeWarningCode other) => ordinal - other.ordinal;
  int get hashCode => ordinal;
  String toString() => name;
}