// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.error;

import 'java_core.dart';
import 'source.dart';
import 'ast.dart' show ASTNode;
import 'scanner.dart' show Token;

/**
 * Instances of the enumeration {@code ErrorSeverity} represent the severity of an {@link ErrorCode}.
 * @coverage dart.engine.error
 */
class ErrorSeverity {
  /**
   * The severity representing a non-error. This is never used for any error code, but is useful for
   * clients.
   */
  static final ErrorSeverity NONE = new ErrorSeverity('NONE', 0, " ", "none");
  /**
   * The severity representing a warning. Warnings can become errors if the {@code -Werror} command
   * line flag is specified.
   */
  static final ErrorSeverity WARNING = new ErrorSeverity('WARNING', 1, "W", "warning");
  /**
   * The severity representing an error.
   */
  static final ErrorSeverity ERROR = new ErrorSeverity('ERROR', 2, "E", "error");
  static final List<ErrorSeverity> values = [NONE, WARNING, ERROR];
  final String __name;
  final int __ordinal;
  int get ordinal => __ordinal;
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
   * @param machineCode the name of the severity used when producing machine output
   * @param displayName the name of the severity used when producing readable output
   */
  ErrorSeverity(this.__name, this.__ordinal, String machineCode, String displayName) {
    this._machineCode = machineCode;
    this._displayName = displayName;
  }
  /**
   * Return the name of the severity used when producing readable output.
   * @return the name of the severity used when producing readable output
   */
  String get displayName => _displayName;
  /**
   * Return the name of the severity used when producing machine output.
   * @return the name of the severity used when producing machine output
   */
  String get machineCode => _machineCode;
  /**
   * Return the severity constant that represents the greatest severity.
   * @param severity the severity being compared against
   * @return the most sever of this or the given severity
   */
  ErrorSeverity max(ErrorSeverity severity) => this.ordinal >= severity.ordinal ? this : severity;
  String toString() => __name;
}
/**
 * Instances of the class {@code ErrorReporter} wrap an error listener with utility methods used to
 * create the errors being reported.
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
   * Report an error with the given error code and arguments.
   * @param errorCode the error code of the error to be reported
   * @param node the node specifying the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportError(ErrorCode errorCode, ASTNode node, List<Object> arguments) {
    _errorListener.onError(new AnalysisError.con2(_source, node.offset, node.length, errorCode, [arguments]));
  }
  /**
   * Report an error with the given error code and arguments.
   * @param errorCode the error code of the error to be reported
   * @param token the token specifying the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportError2(ErrorCode errorCode, Token token, List<Object> arguments) {
    _errorListener.onError(new AnalysisError.con2(_source, token.offset, token.length, errorCode, [arguments]));
  }
  /**
   * Set the source to be used when reporting errors. Setting the source to {@code null} will cause
   * the default source to be used.
   * @param source the source to be used when reporting errors
   */
  void set source(Source source7) {
    this._source = source7 == null ? _defaultSource : source7;
  }
}
/**
 * Instances of the class {@code AnalysisError} represent an error discovered during the analysis of
 * some Dart code.
 * @see AnalysisErrorListener
 * @coverage dart.engine.error
 */
class AnalysisError {
  /**
   * An empty array of errors used when no errors are expected.
   */
  static List<AnalysisError> NO_ERRORS = new List<AnalysisError>(0);
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
    _jtd_constructor_129_impl(source2, errorCode2, arguments);
  }
  _jtd_constructor_129_impl(Source source2, ErrorCode errorCode2, List<Object> arguments) {
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
    _jtd_constructor_130_impl(source3, offset2, length11, errorCode3, arguments);
  }
  _jtd_constructor_130_impl(Source source3, int offset2, int length11, ErrorCode errorCode3, List<Object> arguments) {
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
 * The interface {@code ErrorCode} defines the behavior common to objects representing error codes
 * associated with {@link AnalysisError analysis errors}.
 * @coverage dart.engine.error
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
 * Instances of the enumeration {@code ErrorType} represent the type of an {@link ErrorCode}.
 * @coverage dart.engine.error
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
  int get ordinal => __ordinal;
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
 * The enumeration {@code CompileTimeErrorCode} defines the error codes used for compile time
 * errors. The convention for this class is for the name of the error code to indicate the problem
 * that caused the error to be generated and for the error message to explain what is wrong and,
 * when appropriate, how the problem can be corrected.
 * @coverage dart.engine.error
 */
class CompileTimeErrorCode implements ErrorCode {
  /**
   * 14.2 Exports: It is a compile-time error if a name <i>N</i> is re-exported by a library
   * <i>L</i> and <i>N</i> is introduced into the export namespace of <i>L</i> by more than one
   * export.
   */
  static final CompileTimeErrorCode AMBIGUOUS_EXPORT = new CompileTimeErrorCode('AMBIGUOUS_EXPORT', 0, "");
  /**
   * 14.1 Imports: If a name <i>N</i> is referenced by a library <i>L</i> and <i>N</i> is introduced
   * into the top level scope <i>L</i> by more than one import then:
   * <ol>
   * <li>It is a static warning if <i>N</i> is used as a type annotation.
   * <li>In checked mode, it is a dynamic error if <i>N</i> is used as a type annotation and
   * referenced during a subtype test.
   * <li>Otherwise, it is a compile-time error.
   * </ol>
   */
  static final CompileTimeErrorCode AMBIGUOUS_IMPORT = new CompileTimeErrorCode('AMBIGUOUS_IMPORT', 1, "");
  /**
   * 12.33 Argument Definition Test: It is a compile time error if <i>v</i> does not denote a formal
   * parameter.
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
   * 12.1 Constants: It is a compile-time error if evaluation of a compile-time constant would raise
   * an exception.
   */
  static final CompileTimeErrorCode COMPILE_TIME_CONSTANT_RAISES_EXCEPTION_DIVIDE_BY_ZERO = new CompileTimeErrorCode('COMPILE_TIME_CONSTANT_RAISES_EXCEPTION_DIVIDE_BY_ZERO', 9, "Cannot divide by zero");
  /**
   * 7.6 Constructors: A constructor name always begins with the name of its immediately enclosing
   * class, and may optionally be followed by a dot and an identifier <i>id</i>. It is a
   * compile-time error if <i>id</i> is the name of a member declared in the immediately enclosing
   * class.
   */
  static final CompileTimeErrorCode CONFLICTING_CONSTRUCTOR_NAME_AND_FIELD = new CompileTimeErrorCode('CONFLICTING_CONSTRUCTOR_NAME_AND_FIELD', 10, "'%s' cannot be used to name a constructor and a method in this class");
  /**
   * 7.6 Constructors: A constructor name always begins with the name of its immediately enclosing
   * class, and may optionally be followed by a dot and an identifier <i>id</i>. It is a
   * compile-time error if <i>id</i> is the name of a member declared in the immediately enclosing
   * class.
   */
  static final CompileTimeErrorCode CONFLICTING_CONSTRUCTOR_NAME_AND_METHOD = new CompileTimeErrorCode('CONFLICTING_CONSTRUCTOR_NAME_AND_METHOD', 11, "'%s' cannot be used to name a constructor and a field in this class");
  /**
   * 7.6.3 Constant Constructors: It is a compile-time error if a constant constructor is declared
   * by a class that has a non-final instance variable.
   */
  static final CompileTimeErrorCode CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD = new CompileTimeErrorCode('CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD', 12, "Classes with non-final fields cannot define 'const' constructors");
  /**
   * 6.2 Formal Parameters: It is a compile-time error if a formal parameter is declared as a
   * constant variable.
   */
  static final CompileTimeErrorCode CONST_FORMAL_PARAMETER = new CompileTimeErrorCode('CONST_FORMAL_PARAMETER', 13, "Parameters cannot be 'const'");
  /**
   * 5 Variables: A constant variable must be initialized to a compile-time constant or a
   * compile-time error occurs.
   */
  static final CompileTimeErrorCode CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE = new CompileTimeErrorCode('CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE', 14, "'const' variables must be constant value");
  /**
   * 12.11.2 Const: It is a compile-time error if evaluation of a constant object results in an
   * uncaught exception being thrown.
   */
  static final CompileTimeErrorCode CONST_EVAL_THROWS_EXCEPTION = new CompileTimeErrorCode('CONST_EVAL_THROWS_EXCEPTION', 15, "");
  /**
   * 12.11.2 Const: If <i>T</i> is a parameterized type <i>S&lt;U<sub>1</sub>, &hellip;,
   * U<sub>m</sub>&gt;</i>, let <i>R = S</i>; It is a compile time error if <i>S</i> is not a
   * generic type with <i>m</i> type parameters.
   * @param typeName the name of the type being referenced (<i>S</i>)
   * @param argumentCount the number of type arguments provided
   * @param parameterCount the number of type parameters that were declared
   */
  static final CompileTimeErrorCode CONST_WITH_INVALID_TYPE_PARAMETERS = new CompileTimeErrorCode('CONST_WITH_INVALID_TYPE_PARAMETERS', 16, "The type '%s' is declared with %d type parameters, but %d type arguments were given");
  /**
   * 12.11.2 Const: If <i>e</i> is of the form <i>const T(a<sub>1</sub>, &hellip;, a<sub>n</sub>,
   * x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;, x<sub>n+k</sub>: a<sub>n+k</sub>)</i> it is a
   * compile-time error if the type <i>T</i> does not declare a constant constructor with the same
   * name as the declaration of <i>T</i>.
   */
  static final CompileTimeErrorCode CONST_WITH_NON_CONST = new CompileTimeErrorCode('CONST_WITH_NON_CONST', 17, "The constructor being called is not a 'const' constructor");
  /**
   * 12.11.2 Const: In all of the above cases, it is a compile-time error if <i>a<sub>i</sub>, 1
   * &lt;= i &lt;= n + k</i>, is not a compile-time constant expression.
   */
  static final CompileTimeErrorCode CONST_WITH_NON_CONSTANT_ARGUMENT = new CompileTimeErrorCode('CONST_WITH_NON_CONSTANT_ARGUMENT', 18, "");
  /**
   * 12.11.2 Const: It is a compile-time error if <i>T</i> is not a class accessible in the current
   * scope, optionally followed by type arguments.
   * <p>
   * 12.11.2 Const: If <i>e</i> is of the form <i>const T.id(a<sub>1</sub>, &hellip;, a<sub>n</sub>,
   * x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip; x<sub>n+k</sub>: a<sub>n+k</sub>)</i> it is a
   * compile-time error if <i>T</i> is not a class accessible in the current scope, optionally
   * followed by type arguments.
   */
  static final CompileTimeErrorCode CONST_WITH_NON_TYPE = new CompileTimeErrorCode('CONST_WITH_NON_TYPE', 19, "");
  /**
   * 12.11.2 Const: It is a compile-time error if <i>T</i> includes any type parameters.
   */
  static final CompileTimeErrorCode CONST_WITH_TYPE_PARAMETERS = new CompileTimeErrorCode('CONST_WITH_TYPE_PARAMETERS', 20, "");
  /**
   * 12.11.2 Const: It is a compile-time error if <i>T.id</i> is not the name of a constant
   * constructor declared by the type <i>T</i>.
   */
  static final CompileTimeErrorCode CONST_WITH_UNDEFINED_CONSTRUCTOR = new CompileTimeErrorCode('CONST_WITH_UNDEFINED_CONSTRUCTOR', 21, "");
  /**
   * 15.3.1 Typedef: It is a compile-time error if any default values are specified in the signature
   * of a function type alias.
   */
  static final CompileTimeErrorCode DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS = new CompileTimeErrorCode('DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS', 22, "");
  /**
   * 3.1 Scoping: It is a compile-time error if there is more than one entity with the same name
   * declared in the same scope.
   * @param duplicateName the name of the duplicate entity
   */
  static final CompileTimeErrorCode DUPLICATE_DEFINITION = new CompileTimeErrorCode('DUPLICATE_DEFINITION', 23, "The name '%s' is already defined");
  /**
   * 7 Classes: It is a compile-time error if a class declares two members of the same name.
   */
  static final CompileTimeErrorCode DUPLICATE_MEMBER_NAME = new CompileTimeErrorCode('DUPLICATE_MEMBER_NAME', 24, "");
  /**
   * 7 Classes: It is a compile-time error if a class has an instance member and a static member
   * with the same name.
   */
  static final CompileTimeErrorCode DUPLICATE_MEMBER_NAME_INSTANCE_STATIC = new CompileTimeErrorCode('DUPLICATE_MEMBER_NAME_INSTANCE_STATIC', 25, "");
  /**
   * 12.14.2 Binding Actuals to Formals: It is a compile-time error if <i>q<sub>i</sub> =
   * q<sub>j</sub></i> for any <i>i != j</i> [where <i>q<sub>i</sub></i> is the label for a named
   * argument].
   */
  static final CompileTimeErrorCode DUPLICATE_NAMED_ARGUMENT = new CompileTimeErrorCode('DUPLICATE_NAMED_ARGUMENT', 26, "");
  /**
   * 14.2 Exports: It is a compile-time error if the compilation unit found at the specified URI is
   * not a library declaration.
   */
  static final CompileTimeErrorCode EXPORT_OF_NON_LIBRARY = new CompileTimeErrorCode('EXPORT_OF_NON_LIBRARY', 27, "");
  /**
   * 7.9 Superclasses: It is a compile-time error if the extends clause of a class <i>C</i> includes
   * a type expression that does not denote a class available in the lexical scope of <i>C</i>.
   * @param typeName the name of the superclass that was not found
   */
  static final CompileTimeErrorCode EXTENDS_NON_CLASS = new CompileTimeErrorCode('EXTENDS_NON_CLASS', 28, "Classes can only extend other classes");
  /**
   * 12.2 Null: It is a compile-time error for a class to attempt to extend or implement Null.
   * <p>
   * 12.3 Numbers: It is a compile-time error for a class to attempt to extend or implement int.
   * <p>
   * 12.3 Numbers: It is a compile-time error for a class to attempt to extend or implement double.
   * <p>
   * 12.3 Numbers: It is a compile-time error for any type other than the types int and double to
   * attempt to extend or implement num.
   * <p>
   * 12.4 Booleans: It is a compile-time error for a class to attempt to extend or implement bool.
   * <p>
   * 12.5 Strings: It is a compile-time error for a class to attempt to extend or implement String.
   */
  static final CompileTimeErrorCode EXTENDS_OR_IMPLEMENTS_DISALLOWED_CLASS = new CompileTimeErrorCode('EXTENDS_OR_IMPLEMENTS_DISALLOWED_CLASS', 29, "");
  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It is a compile time
   * error if more than one initializer corresponding to a given instance variable appears in
   * <i>k</i>‚Äôs list.
   */
  static final CompileTimeErrorCode FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS = new CompileTimeErrorCode('FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS', 30, "");
  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It is a compile time
   * error if <i>k</i>‚Äôs initializer list contains an initializer for a final variable <i>f</i>
   * whose declaration includes an initialization expression.
   */
  static final CompileTimeErrorCode FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION = new CompileTimeErrorCode('FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION', 31, "");
  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It is a compile time
   * error if <i>k</i>‚Äôs initializer list contains an initializer for a variable that is initialized
   * by means of an initializing formal of <i>k</i>.
   */
  static final CompileTimeErrorCode FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER = new CompileTimeErrorCode('FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER', 32, "");
  /**
   * 7.6.1 Generative Constructors: It is a compile-time error if an initializing formal is used by
   * a function other than a non-redirecting generative constructor.
   */
  static final CompileTimeErrorCode FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR = new CompileTimeErrorCode('FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR', 33, "");
  /**
   * 5 Variables: It is a compile-time error if a final instance variable that has been initialized
   * at its point of declaration is also initialized in a constructor.
   */
  static final CompileTimeErrorCode FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR = new CompileTimeErrorCode('FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR', 34, "");
  /**
   * 5 Variables: It is a compile-time error if a final instance variable that has is initialized by
   * means of an initializing formal of a constructor is also initialized elsewhere in the same
   * constructor.
   */
  static final CompileTimeErrorCode FINAL_INITIALIZED_MULTIPLE_TIMES = new CompileTimeErrorCode('FINAL_INITIALIZED_MULTIPLE_TIMES', 35, "");
  /**
   * 5 Variables: It is a compile-time error if a library, static or local variable <i>v</i> is
   * final and <i>v</i> is not initialized at its point of declaration.
   */
  static final CompileTimeErrorCode FINAL_NOT_INITIALIZED = new CompileTimeErrorCode('FINAL_NOT_INITIALIZED', 36, "");
  /**
   * 7.2 Getters: It is a compile-time error if a class has both a getter and a method with the same
   * name.
   */
  static final CompileTimeErrorCode GETTER_AND_METHOD_WITH_SAME_NAME = new CompileTimeErrorCode('GETTER_AND_METHOD_WITH_SAME_NAME', 37, "");
  /**
   * 7.10 Superinterfaces: It is a compile-time error if the implements clause of a class includes
   * type dynamic.
   */
  static final CompileTimeErrorCode IMPLEMENTS_DYNAMIC = new CompileTimeErrorCode('IMPLEMENTS_DYNAMIC', 38, "");
  /**
   * 7.10 Superinterfaces: It is a compile-time error if the implements clause of a class <i>C</i>
   * includes a type expression that does not denote a class available in the lexical scope of
   * <i>C</i>.
   * @param typeName the name of the interface that was not found
   */
  static final CompileTimeErrorCode IMPLEMENTS_NON_CLASS = new CompileTimeErrorCode('IMPLEMENTS_NON_CLASS', 39, "Classes can only implement other classes");
  /**
   * 7.10 Superinterfaces: It is a compile-time error if a type <i>T</i> appears more than once in
   * the implements clause of a class.
   */
  static final CompileTimeErrorCode IMPLEMENTS_REPEATED = new CompileTimeErrorCode('IMPLEMENTS_REPEATED', 40, "");
  /**
   * 7.10 Superinterfaces: It is a compile-time error if the interface of a class <i>C</i> is a
   * superinterface of itself.
   */
  static final CompileTimeErrorCode IMPLEMENTS_SELF = new CompileTimeErrorCode('IMPLEMENTS_SELF', 41, "");
  /**
   * 14.1 Imports: It is a compile-time error to import two different libraries with the same name.
   */
  static final CompileTimeErrorCode IMPORT_DUPLICATED_LIBRARY_NAME = new CompileTimeErrorCode('IMPORT_DUPLICATED_LIBRARY_NAME', 42, "");
  /**
   * 14.1 Imports: It is a compile-time error if the compilation unit found at the specified URI is
   * not a library declaration.
   */
  static final CompileTimeErrorCode IMPORT_OF_NON_LIBRARY = new CompileTimeErrorCode('IMPORT_OF_NON_LIBRARY', 43, "");
  /**
   * 13.9 Switch: It is a compile-time error if values of the expressions <i>e<sub>k</sub></i> are
   * not instances of the same class <i>C</i>, for all <i>1 &lt;= k &lt;= n</i>.
   */
  static final CompileTimeErrorCode INCONSITENT_CASE_EXPRESSION_TYPES = new CompileTimeErrorCode('INCONSITENT_CASE_EXPRESSION_TYPES', 44, "");
  /**
   * 7.6.1 Generative Constructors: An initializing formal has the form <i>this.id</i>. It is a
   * compile-time error if <i>id</i> is not the name of an instance variable of the immediately
   * enclosing class.
   */
  static final CompileTimeErrorCode INITIALIZER_FOR_NON_EXISTANT_FIELD = new CompileTimeErrorCode('INITIALIZER_FOR_NON_EXISTANT_FIELD', 45, "");
  /**
   * TODO(brianwilkerson) Remove this when we have decided on how to report errors in compile-time
   * constants. Until then, this acts as a placeholder for more informative errors.
   */
  static final CompileTimeErrorCode INVALID_CONSTANT = new CompileTimeErrorCode('INVALID_CONSTANT', 46, "");
  /**
   * 7.6 Constructors: It is a compile-time error if the name of a constructor is not a constructor
   * name.
   */
  static final CompileTimeErrorCode INVALID_CONSTRUCTOR_NAME = new CompileTimeErrorCode('INVALID_CONSTRUCTOR_NAME', 47, "");
  /**
   * 7.6.2 Factories: It is a compile-time error if <i>M</i> is not the name of the immediately
   * enclosing class.
   */
  static final CompileTimeErrorCode INVALID_FACTORY_NAME_NOT_A_CLASS = new CompileTimeErrorCode('INVALID_FACTORY_NAME_NOT_A_CLASS', 48, "");
  /**
   * 7.1 Instance Methods: It is a static warning if an instance method <i>m1</i> overrides an
   * instance member <i>m2</i>, the signature of <i>m2</i> explicitly specifies a default value for
   * a formal parameter <i>p</i> and the signature of <i>m1</i> specifies a different default value
   * for <i>p</i>.
   */
  static final CompileTimeErrorCode INVALID_OVERRIDE_DEFAULT_VALUE = new CompileTimeErrorCode('INVALID_OVERRIDE_DEFAULT_VALUE', 49, "");
  /**
   * 7.1: It is a compile-time error if an instance method <i>m1</i> overrides an instance member
   * <i>m2</i> and <i>m1</i> does not declare all the named parameters declared by <i>m2</i>.
   */
  static final CompileTimeErrorCode INVALID_OVERRIDE_NAMED = new CompileTimeErrorCode('INVALID_OVERRIDE_NAMED', 50, "");
  /**
   * 7.1 Instance Methods: It is a compile-time error if an instance method m1 overrides an instance
   * member <i>m2</i> and <i>m1</i> has fewer optional positional parameters than <i>m2</i>.
   */
  static final CompileTimeErrorCode INVALID_OVERRIDE_POSITIONAL = new CompileTimeErrorCode('INVALID_OVERRIDE_POSITIONAL', 51, "");
  /**
   * 7.1 Instance Methods: It is a compile-time error if an instance method <i>m1</i> overrides an
   * instance member <i>m2</i> and <i>m1</i> has a different number of required parameters than
   * <i>m2</i>.
   */
  static final CompileTimeErrorCode INVALID_OVERRIDE_REQUIRED = new CompileTimeErrorCode('INVALID_OVERRIDE_REQUIRED', 52, "");
  /**
   * 12.10 This: It is a compile-time error if this appears in a top-level function or variable
   * initializer, in a factory constructor, or in a static method or variable initializer, or in the
   * initializer of an instance variable.
   */
  static final CompileTimeErrorCode INVALID_REFERENCE_TO_THIS = new CompileTimeErrorCode('INVALID_REFERENCE_TO_THIS', 53, "");
  /**
   * 12.7 Maps: It is a compile-time error if the first type argument to a map literal is not
   * String.
   */
  static final CompileTimeErrorCode INVALID_TYPE_ARGUMENT_FOR_KEY = new CompileTimeErrorCode('INVALID_TYPE_ARGUMENT_FOR_KEY', 54, "");
  /**
   * 12.6 Lists: It is a compile time error if the type argument of a constant list literal includes
   * a type parameter.
   */
  static final CompileTimeErrorCode INVALID_TYPE_ARGUMENT_IN_CONST_LIST = new CompileTimeErrorCode('INVALID_TYPE_ARGUMENT_IN_CONST_LIST', 55, "");
  /**
   * 12.7 Maps: It is a compile time error if the type arguments of a constant map literal include a
   * type parameter.
   */
  static final CompileTimeErrorCode INVALID_TYPE_ARGUMENT_IN_CONST_MAP = new CompileTimeErrorCode('INVALID_TYPE_ARGUMENT_IN_CONST_MAP', 56, "");
  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It is a compile-time
   * error if <i>k</i>'s initializer list contains an initializer for a variable that is not an
   * instance variable declared in the immediately surrounding class.
   */
  static final CompileTimeErrorCode INVALID_VARIABLE_IN_INITIALIZER = new CompileTimeErrorCode('INVALID_VARIABLE_IN_INITIALIZER', 57, "");
  /**
   * 13.13 Break: It is a compile-time error if no such statement <i>s<sub>E</sub></i> exists within
   * the innermost function in which <i>s<sub>b</sub></i> occurs.
   * <p>
   * 13.14 Continue: It is a compile-time error if no such statement or case clause
   * <i>s<sub>E</sub></i> exists within the innermost function in which <i>s<sub>c</sub></i> occurs.
   * @param labelName the name of the unresolvable label
   */
  static final CompileTimeErrorCode LABEL_IN_OUTER_SCOPE = new CompileTimeErrorCode('LABEL_IN_OUTER_SCOPE', 58, "Cannot reference label '%s' declared in an outer method");
  /**
   * 13.13 Break: It is a compile-time error if no such statement <i>s<sub>E</sub></i> exists within
   * the innermost function in which <i>s<sub>b</sub></i> occurs.
   * <p>
   * 13.14 Continue: It is a compile-time error if no such statement or case clause
   * <i>s<sub>E</sub></i> exists within the innermost function in which <i>s<sub>c</sub></i> occurs.
   * @param labelName the name of the unresolvable label
   */
  static final CompileTimeErrorCode LABEL_UNDEFINED = new CompileTimeErrorCode('LABEL_UNDEFINED', 59, "Cannot reference undefined label '%s'");
  /**
   * 7 Classes: It is a compile time error if a class <i>C</i> declares a member with the same name
   * as <i>C</i>.
   */
  static final CompileTimeErrorCode MEMBER_WITH_CLASS_NAME = new CompileTimeErrorCode('MEMBER_WITH_CLASS_NAME', 60, "");
  /**
   * 9 Mixins: It is a compile-time error if a declared or derived mixin explicitly declares a
   * constructor.
   */
  static final CompileTimeErrorCode MIXIN_DECLARES_CONSTRUCTOR = new CompileTimeErrorCode('MIXIN_DECLARES_CONSTRUCTOR', 61, "");
  /**
   * 9 Mixins: It is a compile-time error if a mixin is derived from a class whose superclass is not
   * Object.
   */
  static final CompileTimeErrorCode MIXIN_INHERITS_FROM_NOT_OBJECT = new CompileTimeErrorCode('MIXIN_INHERITS_FROM_NOT_OBJECT', 62, "");
  /**
   * 9.1 Mixin Application: It is a compile-time error if <i>M</i> does not denote a class or mixin
   * available in the immediately enclosing scope.
   * @param typeName the name of the mixin that was not found
   */
  static final CompileTimeErrorCode MIXIN_OF_NON_CLASS = new CompileTimeErrorCode('MIXIN_OF_NON_CLASS', 63, "Classes can only mixin other classes");
  /**
   * 9.1 Mixin Application: If <i>M</i> is a class, it is a compile time error if a well formed
   * mixin cannot be derived from <i>M</i>.
   */
  static final CompileTimeErrorCode MIXIN_OF_NON_MIXIN = new CompileTimeErrorCode('MIXIN_OF_NON_MIXIN', 64, "");
  /**
   * 9 Mixins: It is a compile-time error if a declared or derived mixin refers to super.
   */
  static final CompileTimeErrorCode MIXIN_REFERENCES_SUPER = new CompileTimeErrorCode('MIXIN_REFERENCES_SUPER', 65, "");
  /**
   * 9.1 Mixin Application: It is a compile-time error if <i>S</i> does not denote a class available
   * in the immediately enclosing scope.
   */
  static final CompileTimeErrorCode MIXIN_WITH_NON_CLASS_SUPERCLASS = new CompileTimeErrorCode('MIXIN_WITH_NON_CLASS_SUPERCLASS', 66, "");
  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. Then <i>k</i> may
   * include at most one superinitializer in its initializer list or a compile time error occurs.
   */
  static final CompileTimeErrorCode MULTIPLE_SUPER_INITIALIZERS = new CompileTimeErrorCode('MULTIPLE_SUPER_INITIALIZERS', 67, "");
  /**
   * 12.11.1 New: It is a compile time error if <i>S</i> is not a generic type with <i>m</i> type
   * parameters.
   * @param typeName the name of the type being referenced (<i>S</i>)
   * @param argumentCount the number of type arguments provided
   * @param parameterCount the number of type parameters that were declared
   */
  static final CompileTimeErrorCode NEW_WITH_INVALID_TYPE_PARAMETERS = new CompileTimeErrorCode('NEW_WITH_INVALID_TYPE_PARAMETERS', 68, "The type '%s' is declared with %d type parameters, but %d type arguments were given");
  /**
   * 13.2 Expression Statements: It is a compile-time error if a non-constant map literal that has
   * no explicit type arguments appears in a place where a statement is expected.
   */
  static final CompileTimeErrorCode NON_CONST_MAP_AS_EXPRESSION_STATEMENT = new CompileTimeErrorCode('NON_CONST_MAP_AS_EXPRESSION_STATEMENT', 69, "");
  /**
   * 13.9 Switch: Given a switch statement of the form <i>switch (e) { label<sub>11</sub> &hellip;
   * label<sub>1j1</sub> case e<sub>1</sub>: s<sub>1</sub> &hellip; label<sub>n1</sub> &hellip;
   * label<sub>njn</sub> case e<sub>n</sub>: s<sub>n</sub> default: s<sub>n+1</sub>}</i> or the form
   * <i>switch (e) { label<sub>11</sub> &hellip; label<sub>1j1</sub> case e<sub>1</sub>:
   * s<sub>1</sub> &hellip; label<sub>n1</sub> &hellip; label<sub>njn</sub> case e<sub>n</sub>:
   * s<sub>n</sub>}</i>, it is a compile-time error if the expressions <i>e<sub>k</sub></i> are not
   * compile-time constants, for all <i>1 &lt;= k &lt;= n</i>.
   */
  static final CompileTimeErrorCode NON_CONSTANT_CASE_EXPRESSION = new CompileTimeErrorCode('NON_CONSTANT_CASE_EXPRESSION', 70, "Case expressions must be constant");
  /**
   * 6.2.2 Optional Formals: It is a compile-time error if the default value of an optional
   * parameter is not a compile-time constant.
   */
  static final CompileTimeErrorCode NON_CONSTANT_DEFAULT_VALUE = new CompileTimeErrorCode('NON_CONSTANT_DEFAULT_VALUE', 71, "Default values of an optional parameter must be constant");
  /**
   * 12.6 Lists: It is a compile time error if an element of a constant list literal is not a
   * compile-time constant.
   */
  static final CompileTimeErrorCode NON_CONSTANT_LIST_ELEMENT = new CompileTimeErrorCode('NON_CONSTANT_LIST_ELEMENT', 72, "'const' lists must have all constant values");
  /**
   * 12.7 Maps: It is a compile time error if either a key or a value of an entry in a constant map
   * literal is not a compile-time constant.
   */
  static final CompileTimeErrorCode NON_CONSTANT_MAP_KEY = new CompileTimeErrorCode('NON_CONSTANT_MAP_KEY', 73, "The keys in a 'const' map must be constant");
  /**
   * 12.7 Maps: It is a compile time error if either a key or a value of an entry in a constant map
   * literal is not a compile-time constant.
   */
  static final CompileTimeErrorCode NON_CONSTANT_MAP_VALUE = new CompileTimeErrorCode('NON_CONSTANT_MAP_VALUE', 74, "The values in a 'const' map must be constant");
  /**
   * 7.6.3 Constant Constructors: Any expression that appears within the initializer list of a
   * constant constructor must be a potentially constant expression, or a compile-time error occurs.
   */
  static final CompileTimeErrorCode NON_CONSTANT_VALUE_IN_INITIALIZER = new CompileTimeErrorCode('NON_CONSTANT_VALUE_IN_INITIALIZER', 75, "");
  /**
   * 7.9 Superclasses: It is a compile-time error to specify an extends clause for class Object.
   */
  static final CompileTimeErrorCode OBJECT_CANNOT_EXTEND_ANOTHER_CLASS = new CompileTimeErrorCode('OBJECT_CANNOT_EXTEND_ANOTHER_CLASS', 76, "");
  /**
   * 7.1.1 Operators: It is a compile-time error to declare an optional parameter in an operator.
   */
  static final CompileTimeErrorCode OPTIONAL_PARAMETER_IN_OPERATOR = new CompileTimeErrorCode('OPTIONAL_PARAMETER_IN_OPERATOR', 77, "");
  /**
   * 8 Interfaces: It is a compile-time error if an interface member <i>m1</i> overrides an
   * interface member <i>m2</i> and <i>m1</i> does not declare all the named parameters declared by
   * <i>m2</i> in the same order.
   */
  static final CompileTimeErrorCode OVERRIDE_MISSING_NAMED_PARAMETERS = new CompileTimeErrorCode('OVERRIDE_MISSING_NAMED_PARAMETERS', 78, "");
  /**
   * 8 Interfaces: It is a compile-time error if an interface member <i>m1</i> overrides an
   * interface member <i>m2</i> and <i>m1</i> has a different number of required parameters than
   * <i>m2</i>.
   */
  static final CompileTimeErrorCode OVERRIDE_MISSING_REQUIRED_PARAMETERS = new CompileTimeErrorCode('OVERRIDE_MISSING_REQUIRED_PARAMETERS', 79, "");
  /**
   * 14.3 Parts: It is a compile time error if the contents of the URI are not a valid part
   * declaration.
   */
  static final CompileTimeErrorCode PART_OF_NON_PART = new CompileTimeErrorCode('PART_OF_NON_PART', 80, "");
  /**
   * 14.1 Imports: It is a compile-time error if the current library declares a top-level member
   * named <i>p</i>.
   */
  static final CompileTimeErrorCode PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER = new CompileTimeErrorCode('PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER', 81, "");
  /**
   * 6.2.2 Optional Formals: It is a compile-time error if the name of a named optional parameter
   * begins with an ‚Äò_‚Äô character.
   */
  static final CompileTimeErrorCode PRIVATE_OPTIONAL_PARAMETER = new CompileTimeErrorCode('PRIVATE_OPTIONAL_PARAMETER', 82, "");
  /**
   * 12.1 Constants: It is a compile-time error if the value of a compile-time constant expression
   * depends on itself.
   */
  static final CompileTimeErrorCode RECURSIVE_COMPILE_TIME_CONSTANT = new CompileTimeErrorCode('RECURSIVE_COMPILE_TIME_CONSTANT', 83, "");
  /**
   * 7.6.2 Factories: It is a compile-time error if a redirecting factory constructor redirects to
   * itself, either directly or indirectly via a sequence of redirections.
   */
  static final CompileTimeErrorCode RECURSIVE_FACTORY_REDIRECT = new CompileTimeErrorCode('RECURSIVE_FACTORY_REDIRECT', 84, "");
  /**
   * 15.3.1 Typedef: It is a compile-time error if a typedef refers to itself via a chain of
   * references that does not include a class type.
   */
  static final CompileTimeErrorCode RECURSIVE_FUNCTION_TYPE_ALIAS = new CompileTimeErrorCode('RECURSIVE_FUNCTION_TYPE_ALIAS', 85, "");
  /**
   * 8.1 Superinterfaces: It is a compile-time error if an interface is a superinterface of itself.
   */
  static final CompileTimeErrorCode RECURSIVE_INTERFACE_INHERITANCE = new CompileTimeErrorCode('RECURSIVE_INTERFACE_INHERITANCE', 86, "");
  /**
   * 7.6.2 Factories: It is a compile-time error if <i>k</i> is prefixed with the const modifier but
   * <i>k‚Äô</i> is not a constant constructor.
   */
  static final CompileTimeErrorCode REDIRECT_TO_NON_CONST_CONSTRUCTOR = new CompileTimeErrorCode('REDIRECT_TO_NON_CONST_CONSTRUCTOR', 87, "");
  /**
   * 13.3 Local Variable Declaration: It is a compile-time error if <i>e</i> refers to the name
   * <i>v</i> or the name <i>v=</i>.
   */
  static final CompileTimeErrorCode REFERENCE_TO_DECLARED_VARIABLE_IN_INITIALIZER = new CompileTimeErrorCode('REFERENCE_TO_DECLARED_VARIABLE_IN_INITIALIZER', 88, "");
  /**
   * 16.1.1 Reserved Words: A reserved word may not be used as an identifier; it is a compile-time
   * error if a reserved word is used where an identifier is expected.
   */
  static final CompileTimeErrorCode RESERVED_WORD_AS_IDENTIFIER = new CompileTimeErrorCode('RESERVED_WORD_AS_IDENTIFIER', 89, "");
  /**
   * 13.11 Return: It is a compile-time error if a return statement of the form <i>return e;</i>
   * appears in a generative constructor.
   */
  static final CompileTimeErrorCode RETURN_IN_GENERATIVE_CONSTRUCTOR = new CompileTimeErrorCode('RETURN_IN_GENERATIVE_CONSTRUCTOR', 90, "");
  /**
   * 6.1 Function Declarations: It is a compile-time error to preface a function declaration with
   * the built-in identifier static.
   */
  static final CompileTimeErrorCode STATIC_TOP_LEVEL_FUNCTION = new CompileTimeErrorCode('STATIC_TOP_LEVEL_FUNCTION', 91, "");
  /**
   * 5 Variables: It is a compile-time error to preface a top level variable declaration with the
   * built-in identifier static.
   */
  static final CompileTimeErrorCode STATIC_TOP_LEVEL_VARIABLE = new CompileTimeErrorCode('STATIC_TOP_LEVEL_VARIABLE', 92, "");
  /**
   * 12.15.4 Super Invocation: A super method invocation <i>i</i> has the form
   * <i>super.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;
   * x<sub>n+k</sub>: a<sub>n+k</sub>)</i>. It is a compile-time error if a super method invocation
   * occurs in a top-level function or variable initializer, in an instance variable initializer or
   * initializer list, in class Object, in a factory constructor, or in a static method or variable
   * initializer.
   */
  static final CompileTimeErrorCode SUPER_IN_INVALID_CONTEXT = new CompileTimeErrorCode('SUPER_IN_INVALID_CONTEXT', 93, "");
  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It is a compile-time
   * error if a generative constructor of class Object includes a superinitializer.
   */
  static final CompileTimeErrorCode SUPER_INITIALIZER_IN_OBJECT = new CompileTimeErrorCode('SUPER_INITIALIZER_IN_OBJECT', 94, "");
  /**
   * 12.8 Throw: It is a compile-time error if an expression of the form throw; is not enclosed
   * within a on-catch clause.
   */
  static final CompileTimeErrorCode THROW_WITHOUT_VALUE_OUTSIDE_ON = new CompileTimeErrorCode('THROW_WITHOUT_VALUE_OUTSIDE_ON', 95, "");
  /**
   * 12.11 Instance Creation: It is a compile-time error if a constructor of a non-generic type
   * invoked by a new expression or a constant object expression is passed any type arguments.
   * <p>
   * 12.32 Type Cast: It is a compile-time error if <i>T</i> is a parameterized type of the form
   * <i>G&lt;T<sub>1</sub>, &hellip;, T<sub>n</sub>&gt;</i> and <i>G</i> is not a generic type with
   * <i>n</i> type parameters.
   */
  static final CompileTimeErrorCode TYPE_ARGUMENTS_FOR_NON_GENERIC_CLASS = new CompileTimeErrorCode('TYPE_ARGUMENTS_FOR_NON_GENERIC_CLASS', 96, "");
  /**
   * 7.6.1 Generative Constructors: Let <i>C</i> be the class in which the superinitializer appears
   * and let <i>S</i> be the superclass of <i>C</i>. Let <i>k</i> be a generative constructor. It is
   * a compile-time error if class <i>S</i> does not declare a generative constructor named <i>S</i>
   * (respectively <i>S.id</i>)
   */
  static final CompileTimeErrorCode UNDEFINED_CONSTRUCTOR_IN_INITIALIZER = new CompileTimeErrorCode('UNDEFINED_CONSTRUCTOR_IN_INITIALIZER', 97, "");
  /**
   * 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. Each final instance
   * variable <i>f</i> declared in the immediately enclosing class must have an initializer in
   * <i>k</i>'s initializer list unless it has already been initialized by one of the following
   * means:
   * <ol>
   * <li>Initialization at the declaration of <i>f</i>.
   * <li>Initialization by means of an initializing formal of <i>k</i>.
   * </ol>
   * or a compile-time error occurs.
   */
  static final CompileTimeErrorCode UNINITIALIZED_FINAL_FIELD = new CompileTimeErrorCode('UNINITIALIZED_FINAL_FIELD', 98, "");
  /**
   * 14.1 Imports: It is a compile-time error if <i>x</i> is not a compile-time constant, or if
   * <i>x</i> involves string interpolation.
   * <p>
   * 14.3 Parts: It is a compile-time error if <i>s</i> is not a compile-time constant, or if
   * <i>s</i> involves string interpolation.
   * <p>
   * 14.5 URIs: It is a compile-time error if the string literal <i>x</i> that describes a URI is
   * not a compile-time constant, or if <i>x</i> involves string interpolation.
   */
  static final CompileTimeErrorCode URI_WITH_INTERPOLATION = new CompileTimeErrorCode('URI_WITH_INTERPOLATION', 99, "URIs cannot use string interpolation");
  /**
   * 7.1.1 Operators: It is a compile-time error if the arity of the user-declared operator []= is
   * not 2. It is a compile time error if the arity of a user-declared operator with one of the
   * names: &lt;, &gt;, &lt;=, &gt;=, ==, +, /, ~/, *, %, |, ^, &, &lt;&lt;, &gt;&gt;, [] is not 1.
   * It is a compile time error if the arity of the user-declared operator - is not 0 or 1. It is a
   * compile time error if the arity of the user-declared operator ~ is not 0.
   */
  static final CompileTimeErrorCode WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR = new CompileTimeErrorCode('WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR', 100, "");
  /**
   * 7.3 Setters: It is a compile-time error if a setter‚Äôs formal parameter list does not include
   * exactly one required formal parameter <i>p</i>.
   */
  static final CompileTimeErrorCode WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER = new CompileTimeErrorCode('WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER', 101, "");
  /**
   * 12.11 Instance Creation: It is a compile-time error if a constructor of a generic type with
   * <i>n</i> type parameters invoked by a new expression or a constant object expression is passed
   * <i>m</i> type arguments where <i>m != n</i>.
   * <p>
   * 12.31 Type Test: It is a compile-time error if <i>T</i> is a parameterized type of the form
   * <i>G&lt;T<sub>1</sub>, &hellip;, T<sub>n</sub>&gt;</i> and <i>G</i> is not a generic type with
   * <i>n</i> type parameters.
   */
  static final CompileTimeErrorCode WRONG_NUMBER_OF_TYPE_ARGUMENTS = new CompileTimeErrorCode('WRONG_NUMBER_OF_TYPE_ARGUMENTS', 102, "");
  static final List<CompileTimeErrorCode> values = [AMBIGUOUS_EXPORT, AMBIGUOUS_IMPORT, ARGUMENT_DEFINITION_TEST_NON_PARAMETER, BUILT_IN_IDENTIFIER_AS_TYPE, BUILT_IN_IDENTIFIER_AS_TYPE_NAME, BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME, BUILT_IN_IDENTIFIER_AS_TYPE_VARIABLE_NAME, CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS, COMPILE_TIME_CONSTANT_RAISES_EXCEPTION, COMPILE_TIME_CONSTANT_RAISES_EXCEPTION_DIVIDE_BY_ZERO, CONFLICTING_CONSTRUCTOR_NAME_AND_FIELD, CONFLICTING_CONSTRUCTOR_NAME_AND_METHOD, CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD, CONST_FORMAL_PARAMETER, CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, CONST_EVAL_THROWS_EXCEPTION, CONST_WITH_INVALID_TYPE_PARAMETERS, CONST_WITH_NON_CONST, CONST_WITH_NON_CONSTANT_ARGUMENT, CONST_WITH_NON_TYPE, CONST_WITH_TYPE_PARAMETERS, CONST_WITH_UNDEFINED_CONSTRUCTOR, DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS, DUPLICATE_DEFINITION, DUPLICATE_MEMBER_NAME, DUPLICATE_MEMBER_NAME_INSTANCE_STATIC, DUPLICATE_NAMED_ARGUMENT, EXPORT_OF_NON_LIBRARY, EXTENDS_NON_CLASS, EXTENDS_OR_IMPLEMENTS_DISALLOWED_CLASS, FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS, FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION, FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER, FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR, FINAL_INITIALIZED_MULTIPLE_TIMES, FINAL_NOT_INITIALIZED, GETTER_AND_METHOD_WITH_SAME_NAME, IMPLEMENTS_DYNAMIC, IMPLEMENTS_NON_CLASS, IMPLEMENTS_REPEATED, IMPLEMENTS_SELF, IMPORT_DUPLICATED_LIBRARY_NAME, IMPORT_OF_NON_LIBRARY, INCONSITENT_CASE_EXPRESSION_TYPES, INITIALIZER_FOR_NON_EXISTANT_FIELD, INVALID_CONSTANT, INVALID_CONSTRUCTOR_NAME, INVALID_FACTORY_NAME_NOT_A_CLASS, INVALID_OVERRIDE_DEFAULT_VALUE, INVALID_OVERRIDE_NAMED, INVALID_OVERRIDE_POSITIONAL, INVALID_OVERRIDE_REQUIRED, INVALID_REFERENCE_TO_THIS, INVALID_TYPE_ARGUMENT_FOR_KEY, INVALID_TYPE_ARGUMENT_IN_CONST_LIST, INVALID_TYPE_ARGUMENT_IN_CONST_MAP, INVALID_VARIABLE_IN_INITIALIZER, LABEL_IN_OUTER_SCOPE, LABEL_UNDEFINED, MEMBER_WITH_CLASS_NAME, MIXIN_DECLARES_CONSTRUCTOR, MIXIN_INHERITS_FROM_NOT_OBJECT, MIXIN_OF_NON_CLASS, MIXIN_OF_NON_MIXIN, MIXIN_REFERENCES_SUPER, MIXIN_WITH_NON_CLASS_SUPERCLASS, MULTIPLE_SUPER_INITIALIZERS, NEW_WITH_INVALID_TYPE_PARAMETERS, NON_CONST_MAP_AS_EXPRESSION_STATEMENT, NON_CONSTANT_CASE_EXPRESSION, NON_CONSTANT_DEFAULT_VALUE, NON_CONSTANT_LIST_ELEMENT, NON_CONSTANT_MAP_KEY, NON_CONSTANT_MAP_VALUE, NON_CONSTANT_VALUE_IN_INITIALIZER, OBJECT_CANNOT_EXTEND_ANOTHER_CLASS, OPTIONAL_PARAMETER_IN_OPERATOR, OVERRIDE_MISSING_NAMED_PARAMETERS, OVERRIDE_MISSING_REQUIRED_PARAMETERS, PART_OF_NON_PART, PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER, PRIVATE_OPTIONAL_PARAMETER, RECURSIVE_COMPILE_TIME_CONSTANT, RECURSIVE_FACTORY_REDIRECT, RECURSIVE_FUNCTION_TYPE_ALIAS, RECURSIVE_INTERFACE_INHERITANCE, REDIRECT_TO_NON_CONST_CONSTRUCTOR, REFERENCE_TO_DECLARED_VARIABLE_IN_INITIALIZER, RESERVED_WORD_AS_IDENTIFIER, RETURN_IN_GENERATIVE_CONSTRUCTOR, STATIC_TOP_LEVEL_FUNCTION, STATIC_TOP_LEVEL_VARIABLE, SUPER_IN_INVALID_CONTEXT, SUPER_INITIALIZER_IN_OBJECT, THROW_WITHOUT_VALUE_OUTSIDE_ON, TYPE_ARGUMENTS_FOR_NON_GENERIC_CLASS, UNDEFINED_CONSTRUCTOR_IN_INITIALIZER, UNINITIALIZED_FINAL_FIELD, URI_WITH_INTERPOLATION, WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR, WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER, WRONG_NUMBER_OF_TYPE_ARGUMENTS];
  final String __name;
  final int __ordinal;
  int get ordinal => __ordinal;
  /**
   * The message template used to create the message to be displayed for this error.
   */
  String _message;
  /**
   * Initialize a newly created error code to have the given message.
   * @param message the message template used to create the message to be displayed for the error
   */
  CompileTimeErrorCode(this.__name, this.__ordinal, String message) {
    this._message = message;
  }
  ErrorSeverity get errorSeverity => ErrorType.COMPILE_TIME_ERROR.severity;
  String get message => _message;
  ErrorType get type => ErrorType.COMPILE_TIME_ERROR;
  bool needsRecompilation() => true;
  String toString() => __name;
}
/**
 * The enumeration {@code StaticWarningCode} defines the error codes used for static warnings. The
 * convention for this class is for the name of the error code to indicate the problem that caused
 * the error to be generated and for the error message to explain what is wrong and, when
 * appropriate, how the problem can be corrected.
 * @coverage dart.engine.error
 */
class StaticWarningCode implements ErrorCode {
  /**
   * 12.11.1 New: It is a static warning if the static type of <i>a<sub>i</sub>, 1 &lt;= i &lt;= n+
   * k</i> may not be assigned to the type of the corresponding formal parameter of the constructor
   * <i>T.id</i> (respectively <i>T</i>).
   * <p>
   * 12.11.2 Const: It is a static warning if the static type of <i>a<sub>i</sub>, 1 &lt;= i &lt;=
   * n+ k</i> may not be assigned to the type of the corresponding formal parameter of the
   * constructor <i>T.id</i> (respectively <i>T</i>).
   * <p>
   * 12.14.2 Binding Actuals to Formals: Let <i>T<sub>i</sub></i> be the static type of
   * <i>a<sub>i</sub></i>, let <i>S<sub>i</sub></i> be the type of <i>p<sub>i</sub>, 1 &lt;= i &lt;=
   * n+k</i> and let <i>S<sub>q</sub></i> be the type of the named parameter <i>q</i> of <i>f</i>.
   * It is a static warning if <i>T<sub>j</sub></i> may not be assigned to <i>S<sub>j</sub>, 1 &lt;=
   * j &lt;= m</i>.
   * <p>
   * 12.14.2 Binding Actuals to Formals: Furthermore, each <i>q<sub>i</sub>, 1 &lt;= i &lt;= l</i>,
   * must have a corresponding named parameter in the set <i>{p<sub>n+1</sub>, &hellip;
   * p<sub>n+k</sub>}</i> or a static warning occurs. It is a static warning if
   * <i>T<sub>m+j</sub></i> may not be assigned to <i>S<sub>r</sub></i>, where <i>r = q<sub>j</sub>,
   * 1 &lt;= j &lt;= l</i>.
   */
  static final StaticWarningCode ARGUMENT_TYPE_NOT_ASSIGNABLE = new StaticWarningCode('ARGUMENT_TYPE_NOT_ASSIGNABLE', 0, "");
  /**
   * 5 Variables: Attempting to assign to a final variable elsewhere will cause a NoSuchMethodError
   * to be thrown, because no setter is defined for it. The assignment will also give rise to a
   * static warning for the same reason.
   */
  static final StaticWarningCode ASSIGNMENT_TO_FINAL = new StaticWarningCode('ASSIGNMENT_TO_FINAL', 1, "");
  /**
   * 13.9 Switch: It is a static warning if the last statement of the statement sequence
   * <i>s<sub>k</sub></i> is not a break, continue, return or throw statement.
   */
  static final StaticWarningCode CASE_BLOCK_NOT_TERMINATED = new StaticWarningCode('CASE_BLOCK_NOT_TERMINATED', 2, "");
  /**
   * 12.32 Type Cast: It is a static warning if <i>T</i> does not denote a type available in the
   * current lexical scope.
   */
  static final StaticWarningCode CAST_TO_NON_TYPE = new StaticWarningCode('CAST_TO_NON_TYPE', 3, "");
  /**
   * 16.1.2 Comments: A token of the form <i>[new c](uri)</i> will be replaced by a link in the
   * formatted output. The link will point at the constructor named <i>c</i> in <i>L</i>. The title
   * of the link will be <i>c</i>. It is a static warning if uri is not the URI of a dart library
   * <i>L</i>, or if <i>c</i> is not the name of a constructor of a class declared in the exported
   * namespace of <i>L</i>.
   */
  static final StaticWarningCode COMMENT_REFERENCE_CONSTRUCTOR_NOT_VISIBLE = new StaticWarningCode('COMMENT_REFERENCE_CONSTRUCTOR_NOT_VISIBLE', 4, "");
  /**
   * 16.1.2 Comments: A token of the form <i>[id](uri)</i> will be replaced by a link in the
   * formatted output. The link will point at the declaration named <i>id</i> in <i>L</i>. The title
   * of the link will be <i>id</i>. It is a static warning if uri is not the URI of a dart library
   * <i>L</i>, or if <i>id</i> is not a name declared in the exported namespace of <i>L</i>.
   */
  static final StaticWarningCode COMMENT_REFERENCE_IDENTIFIER_NOT_VISIBLE = new StaticWarningCode('COMMENT_REFERENCE_IDENTIFIER_NOT_VISIBLE', 5, "");
  /**
   * 16.1.2 Comments: It is a static warning if <i>c</i> does not denote a constructor that
   * available in the scope of the documentation comment.
   */
  static final StaticWarningCode COMMENT_REFERENCE_UNDECLARED_CONSTRUCTOR = new StaticWarningCode('COMMENT_REFERENCE_UNDECLARED_CONSTRUCTOR', 6, "");
  /**
   * 16.1.2 Comments: It is a static warning if <i>id</i> does not denote a declaration that
   * available in the scope of the documentation comment.
   */
  static final StaticWarningCode COMMENT_REFERENCE_UNDECLARED_IDENTIFIER = new StaticWarningCode('COMMENT_REFERENCE_UNDECLARED_IDENTIFIER', 7, "");
  /**
   * 16.1.2 Comments: A token of the form <i>[id](uri)</i> will be replaced by a link in the
   * formatted output. The link will point at the declaration named <i>id</i> in <i>L</i>. The title
   * of the link will be <i>id</i>. It is a static warning if uri is not the URI of a dart library
   * <i>L</i>, or if <i>id</i> is not a name declared in the exported namespace of <i>L</i>.
   */
  static final StaticWarningCode COMMENT_REFERENCE_URI_NOT_LIBRARY = new StaticWarningCode('COMMENT_REFERENCE_URI_NOT_LIBRARY', 8, "");
  /**
   * 7.4 Abstract Instance Members: It is a static warning if an abstract member is declared or
   * inherited in a concrete class.
   */
  static final StaticWarningCode CONCRETE_CLASS_WITH_ABSTRACT_MEMBER = new StaticWarningCode('CONCRETE_CLASS_WITH_ABSTRACT_MEMBER', 9, "");
  /**
   * 7.2 Getters: It is a static warning if a class <i>C</i> declares an instance getter named
   * <i>v</i> and an accessible static member named <i>v</i> or <i>v=</i> is declared in a
   * superclass of <i>C</i>.
   */
  static final StaticWarningCode CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER = new StaticWarningCode('CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER', 10, "");
  /**
   * 7.3 Setters: It is a static warning if a class <i>C</i> declares an instance setter named
   * <i>v=</i> and an accessible static member named <i>v=</i> or <i>v</i> is declared in a
   * superclass of <i>C</i>.
   */
  static final StaticWarningCode CONFLICTING_INSTANCE_SETTER_AND_SUPERCLASS_MEMBER = new StaticWarningCode('CONFLICTING_INSTANCE_SETTER_AND_SUPERCLASS_MEMBER', 11, "");
  /**
   * 7.2 Getters: It is a static warning if a class declares a static getter named <i>v</i> and also
   * has a non-static setter named <i>v=</i>.
   */
  static final StaticWarningCode CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER = new StaticWarningCode('CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER', 12, "");
  /**
   * 7.3 Setters: It is a static warning if a class declares a static setter named <i>v=</i> and
   * also has a non-static member named <i>v</i>.
   */
  static final StaticWarningCode CONFLICTING_STATIC_SETTER_AND_INSTANCE_GETTER = new StaticWarningCode('CONFLICTING_STATIC_SETTER_AND_INSTANCE_GETTER', 13, "");
  /**
   * 12.11.2 Const: Given an instance creation expression of the form <i>const q(a<sub>1</sub>,
   * &hellip; a<sub>n</sub>)</i> it is a static warning if <i>q</i> is the constructor of an
   * abstract class but <i>q</i> is not a factory constructor.
   */
  static final StaticWarningCode CONST_WITH_ABSTRACT_CLASS = new StaticWarningCode('CONST_WITH_ABSTRACT_CLASS', 14, "Abstract classes cannot be created with a 'const' expression");
  /**
   * 12.7 Maps: It is a static warning if the values of any two keys in a map literal are equal.
   */
  static final StaticWarningCode EQUAL_KEYS_IN_MAP = new StaticWarningCode('EQUAL_KEYS_IN_MAP', 15, "Keys in a map cannot be equal");
  /**
   * 7.6.1 Generative Constructors: An initializing formal has the form <i>this.id</i>. It is a
   * static warning if the static type of <i>id</i> is not assignable to <i>T<sub>id</sub></i>.
   */
  static final StaticWarningCode FIELD_INITIALIZER_WITH_INVALID_TYPE = new StaticWarningCode('FIELD_INITIALIZER_WITH_INVALID_TYPE', 16, "");
  /**
   * 12.14.2 Binding Actuals to Formals: It is a static warning if <i>m &lt; h</i> or if <i>m &gt;
   * n</i>.
   */
  static final StaticWarningCode INCORRECT_NUMBER_OF_ARGUMENTS = new StaticWarningCode('INCORRECT_NUMBER_OF_ARGUMENTS', 17, "");
  /**
   * 7.1 Instance Methods: It is a static warning if a class <i>C</i> declares an instance method
   * named <i>n</i> and an accessible static member named <i>n</i> is declared in a superclass of
   * <i>C</i>.
   */
  static final StaticWarningCode INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC = new StaticWarningCode('INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC', 18, "");
  /**
   * 7.6.2 Factories: It is a static warning if <i>M.id</i> is not a constructor name.
   */
  static final StaticWarningCode INVALID_FACTORY_NAME = new StaticWarningCode('INVALID_FACTORY_NAME', 19, "");
  /**
   * 7.2 Getters: It is a static warning if a getter <i>m1</i> overrides a getter <i>m2</i> and the
   * type of <i>m1</i> is not a subtype of the type of <i>m2</i>.
   */
  static final StaticWarningCode INVALID_OVERRIDE_GETTER_TYPE = new StaticWarningCode('INVALID_OVERRIDE_GETTER_TYPE', 20, "");
  /**
   * 7.1 Instance Methods: It is a static warning if an instance method <i>m1</i> overrides an
   * instance method <i>m2</i> and the type of <i>m1</i> is not a subtype of the type of <i>m2</i>.
   */
  static final StaticWarningCode INVALID_OVERRIDE_RETURN_TYPE = new StaticWarningCode('INVALID_OVERRIDE_RETURN_TYPE', 21, "");
  /**
   * 7.3 Setters: It is a static warning if a setter <i>m1</i> overrides a setter <i>m2</i> and the
   * type of <i>m1</i> is not a subtype of the type of <i>m2</i>.
   */
  static final StaticWarningCode INVALID_OVERRIDE_SETTER_RETURN_TYPE = new StaticWarningCode('INVALID_OVERRIDE_SETTER_RETURN_TYPE', 22, "");
  /**
   * 12.15.4 Super Invocation: A super method invocation <i>i</i> has the form
   * <i>super.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;
   * x<sub>n+k</sub>: a<sub>n+k</sub>)</i>. If <i>S.m</i> exists, it is a static warning if the type
   * <i>F</i> of <i>S.m</i> may not be assigned to a function type.
   */
  static final StaticWarningCode INVOCATION_OF_NON_FUNCTION = new StaticWarningCode('INVOCATION_OF_NON_FUNCTION', 23, "");
  /**
   * 7.3 Setters: It is a static warning if a class has a setter named <i>v=</i> with argument type
   * <i>T</i> and a getter named <i>v</i> with return type <i>S</i>, and <i>T</i> may not be
   * assigned to <i>S</i>.
   */
  static final StaticWarningCode MISMATCHED_GETTER_AND_SETTER_TYPES = new StaticWarningCode('MISMATCHED_GETTER_AND_SETTER_TYPES', 24, "");
  /**
   * 12.11.1 New: It is a static warning if <i>q</i> is a constructor of an abstract class and
   * <i>q</i> is not a factory constructor.
   */
  static final StaticWarningCode NEW_WITH_ABSTRACT_CLASS = new StaticWarningCode('NEW_WITH_ABSTRACT_CLASS', 25, "Abstract classes cannot be created with a 'new' expression");
  /**
   * 12.11.1 New: It is a static warning if <i>T</i> is not a class accessible in the current scope,
   * optionally followed by type arguments.
   */
  static final StaticWarningCode NEW_WITH_NON_TYPE = new StaticWarningCode('NEW_WITH_NON_TYPE', 26, "");
  /**
   * 12.11.1 New: If <i>T</i> is a class or parameterized type accessible in the current scope then:
   * 1. If <i>e</i> is of the form <i>new T.id(a<sub>1</sub>, &hellip;, a<sub>n</sub>,
   * x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;, x<sub>n+k</sub>: a<sub>n+k</sub>)</i> it is a
   * static warning if <i>T.id</i> is not the name of a constructor declared by the type <i>T</i>.
   * If <i>e</i> of the form <i>new T(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>:
   * a<sub>n+1</sub>, &hellip; x<sub>n+k</sub>: a<sub>n+kM/sub>)</i> it is a static warning if the
   * type <i>T</i> does not declare a constructor with the same name as the declaration of <i>T</i>.
   */
  static final StaticWarningCode NEW_WITH_UNDEFINED_CONSTRUCTOR = new StaticWarningCode('NEW_WITH_UNDEFINED_CONSTRUCTOR', 27, "");
  /**
   * 7.10 Superinterfaces: It is a static warning if the implicit interface of a non-abstract class
   * <i>C</i> includes an instance member <i>m</i> and <i>C</i> does not declare or inherit a
   * corresponding instance member <i>m</i>.
   */
  static final StaticWarningCode NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER = new StaticWarningCode('NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER', 28, "");
  /**
   * 7.9.1 Inheritance and Overriding: It is a static warning if a non-abstract class inherits an
   * abstract method.
   */
  static final StaticWarningCode NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_METHOD = new StaticWarningCode('NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_METHOD', 29, "");
  /**
   * 12.31 Type Test: It is a static warning if <i>T</i> does not denote a type available in the
   * current lexical scope.
   */
  static final StaticWarningCode NON_TYPE = new StaticWarningCode('NON_TYPE', 30, "");
  /**
   * 13.10 Try: An on-catch clause of the form <i>on T catch (p<sub>1</sub>, p<sub>2</sub>) s</i> or
   * <i>on T s</i> matches an object <i>o</i> if the type of <i>o</i> is a subtype of <i>T</i>. It
   * is a static warning if <i>T</i> does not denote a type available in the lexical scope of the
   * catch clause.
   */
  static final StaticWarningCode NON_TYPE_IN_CATCH_CLAUSE = new StaticWarningCode('NON_TYPE_IN_CATCH_CLAUSE', 31, "");
  /**
   * 7.1.1 Operators: It is a static warning if the return type of the user-declared operator []= is
   * explicitly declared and not void.
   */
  static final StaticWarningCode NON_VOID_RETURN_FOR_OPERATOR = new StaticWarningCode('NON_VOID_RETURN_FOR_OPERATOR', 32, "");
  /**
   * 7.3 Setters: It is a static warning if a setter declares a return type other than void.
   */
  static final StaticWarningCode NON_VOID_RETURN_FOR_SETTER = new StaticWarningCode('NON_VOID_RETURN_FOR_SETTER', 33, "");
  /**
   * 8 Interfaces: It is a static warning if an interface member <i>m1</i> overrides an interface
   * member <i>m2</i> and the type of <i>m1</i> is not a subtype of the type of <i>m2</i>.
   */
  static final StaticWarningCode OVERRIDE_NOT_SUBTYPE = new StaticWarningCode('OVERRIDE_NOT_SUBTYPE', 34, "");
  /**
   * 8 Interfaces: It is a static warning if an interface method <i>m1</i> overrides an interface
   * method <i>m2</i>, the signature of <i>m2</i> explicitly specifies a default value for a formal
   * parameter <i>p</i> and the signature of <i>m1</i> specifies a different default value for
   * <i>p</i>.
   */
  static final StaticWarningCode OVERRIDE_WITH_DIFFERENT_DEFAULT = new StaticWarningCode('OVERRIDE_WITH_DIFFERENT_DEFAULT', 35, "");
  /**
   * 14.3 Parts: It is a static warning if the referenced part declaration <i>p</i> names a library
   * other than the current library as the library to which <i>p</i> belongs.
   * @param expectedLibraryName the name of expected library name
   * @param actualLibraryName the non-matching actual library name from the "part of" declaration
   */
  static final StaticWarningCode PART_OF_DIFFERENT_LIBRARY = new StaticWarningCode('PART_OF_DIFFERENT_LIBRARY', 36, "Expected this library to be part of '%s', not '%s'");
  /**
   * 7.6.2 Factories: It is a static warning if the function type of <i>k‚Äô</i> is not a subtype of
   * the type of <i>k</i>.
   */
  static final StaticWarningCode REDIRECT_TO_INVALID_RETURN_TYPE = new StaticWarningCode('REDIRECT_TO_INVALID_RETURN_TYPE', 37, "");
  /**
   * 7.6.2 Factories: It is a static warning if type does not denote a class accessible in the
   * current scope; if type does denote such a class <i>C</i> it is a static warning if the
   * referenced constructor (be it <i>type</i> or <i>type.id</i>) is not a constructor of <i>C</i>.
   */
  static final StaticWarningCode REDIRECT_TO_MISSING_CONSTRUCTOR = new StaticWarningCode('REDIRECT_TO_MISSING_CONSTRUCTOR', 38, "");
  /**
   * 7.6.2 Factories: It is a static warning if type does not denote a class accessible in the
   * current scope; if type does denote such a class <i>C</i> it is a static warning if the
   * referenced constructor (be it <i>type</i> or <i>type.id</i>) is not a constructor of <i>C</i>.
   */
  static final StaticWarningCode REDIRECT_TO_NON_CLASS = new StaticWarningCode('REDIRECT_TO_NON_CLASS', 39, "");
  /**
   * 13.11 Return: Let <i>f</i> be the function immediately enclosing a return statement of the form
   * <i>return;</i> It is a static warning if both of the following conditions hold:
   * <ol>
   * <li><i>f</i> is not a generative constructor.
   * <li>The return type of <i>f</i> may not be assigned to void.
   * </ol>
   */
  static final StaticWarningCode RETURN_WITHOUT_VALUE = new StaticWarningCode('RETURN_WITHOUT_VALUE', 40, "");
  /**
   * 13.9 Switch: It is a static warning if the type of <i>e</i> may not be assigned to the type of
   * <i>e<sub>k</sub></i>.
   */
  static final StaticWarningCode SWITCH_EXPRESSION_NOT_ASSIGNABLE = new StaticWarningCode('SWITCH_EXPRESSION_NOT_ASSIGNABLE', 41, "");
  /**
   * 12.15.3 Static Invocation: A static method invocation <i>i</i> has the form
   * <i>C.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;
   * x<sub>n+k</sub>: a<sub>n+k</sub>)</i>. It is a static warning if <i>C</i> does not denote a
   * class in the current scope.
   */
  static final StaticWarningCode UNDEFINED_CLASS = new StaticWarningCode('UNDEFINED_CLASS', 42, "");
  /**
   * 12.17 Getter Invocation: It is a static warning if there is no class <i>C</i> in the enclosing
   * lexical scope of <i>i</i>, or if <i>C</i> does not declare, implicitly or explicitly, a getter
   * named <i>m</i>.
   */
  static final StaticWarningCode UNDEFINED_GETTER = new StaticWarningCode('UNDEFINED_GETTER', 43, "");
  /**
   * 12.30 Identifier Reference: It is as static warning if an identifier expression of the form
   * <i>id</i> occurs inside a top level or static function (be it function, method, getter, or
   * setter) or variable initializer and there is no declaration <i>d</i> with name <i>id</i> in the
   * lexical scope enclosing the expression.
   */
  static final StaticWarningCode UNDEFINED_IDENTIFIER = new StaticWarningCode('UNDEFINED_IDENTIFIER', 44, "");
  /**
   * 12.18 Assignment: It is as static warning if an assignment of the form <i>v = e</i> occurs
   * inside a top level or static function (be it function, method, getter, or setter) or variable
   * initializer and there is no declaration <i>d</i> with name <i>v=</i> in the lexical scope
   * enclosing the assignment.
   * <p>
   * 12.18 Assignment: It is a static warning if there is no class <i>C</i> in the enclosing lexical
   * scope of the assignment, or if <i>C</i> does not declare, implicitly or explicitly, a setter
   * <i>v=</i>.
   */
  static final StaticWarningCode UNDEFINED_SETTER = new StaticWarningCode('UNDEFINED_SETTER', 45, "");
  /**
   * 12.15.3 Static Invocation: It is a static warning if <i>C</i> does not declare a static method
   * or getter <i>m</i>.
   */
  static final StaticWarningCode UNDEFINED_STATIC_METHOD_OR_GETTER = new StaticWarningCode('UNDEFINED_STATIC_METHOD_OR_GETTER', 46, "");
  static final List<StaticWarningCode> values = [ARGUMENT_TYPE_NOT_ASSIGNABLE, ASSIGNMENT_TO_FINAL, CASE_BLOCK_NOT_TERMINATED, CAST_TO_NON_TYPE, COMMENT_REFERENCE_CONSTRUCTOR_NOT_VISIBLE, COMMENT_REFERENCE_IDENTIFIER_NOT_VISIBLE, COMMENT_REFERENCE_UNDECLARED_CONSTRUCTOR, COMMENT_REFERENCE_UNDECLARED_IDENTIFIER, COMMENT_REFERENCE_URI_NOT_LIBRARY, CONCRETE_CLASS_WITH_ABSTRACT_MEMBER, CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER, CONFLICTING_INSTANCE_SETTER_AND_SUPERCLASS_MEMBER, CONFLICTING_STATIC_GETTER_AND_INSTANCE_SETTER, CONFLICTING_STATIC_SETTER_AND_INSTANCE_GETTER, CONST_WITH_ABSTRACT_CLASS, EQUAL_KEYS_IN_MAP, FIELD_INITIALIZER_WITH_INVALID_TYPE, INCORRECT_NUMBER_OF_ARGUMENTS, INSTANCE_METHOD_NAME_COLLIDES_WITH_SUPERCLASS_STATIC, INVALID_FACTORY_NAME, INVALID_OVERRIDE_GETTER_TYPE, INVALID_OVERRIDE_RETURN_TYPE, INVALID_OVERRIDE_SETTER_RETURN_TYPE, INVOCATION_OF_NON_FUNCTION, MISMATCHED_GETTER_AND_SETTER_TYPES, NEW_WITH_ABSTRACT_CLASS, NEW_WITH_NON_TYPE, NEW_WITH_UNDEFINED_CONSTRUCTOR, NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER, NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_METHOD, NON_TYPE, NON_TYPE_IN_CATCH_CLAUSE, NON_VOID_RETURN_FOR_OPERATOR, NON_VOID_RETURN_FOR_SETTER, OVERRIDE_NOT_SUBTYPE, OVERRIDE_WITH_DIFFERENT_DEFAULT, PART_OF_DIFFERENT_LIBRARY, REDIRECT_TO_INVALID_RETURN_TYPE, REDIRECT_TO_MISSING_CONSTRUCTOR, REDIRECT_TO_NON_CLASS, RETURN_WITHOUT_VALUE, SWITCH_EXPRESSION_NOT_ASSIGNABLE, UNDEFINED_CLASS, UNDEFINED_GETTER, UNDEFINED_IDENTIFIER, UNDEFINED_SETTER, UNDEFINED_STATIC_METHOD_OR_GETTER];
  final String __name;
  final int __ordinal;
  int get ordinal => __ordinal;
  /**
   * The message template used to create the message to be displayed for this error.
   */
  String _message;
  /**
   * Initialize a newly created error code to have the given type and message.
   * @param message the message template used to create the message to be displayed for the error
   */
  StaticWarningCode(this.__name, this.__ordinal, String message) {
    this._message = message;
  }
  ErrorSeverity get errorSeverity => ErrorType.STATIC_WARNING.severity;
  String get message => _message;
  ErrorType get type => ErrorType.STATIC_WARNING;
  bool needsRecompilation() => true;
  String toString() => __name;
}
/**
 * The interface {@code AnalysisErrorListener} defines the behavior of objects that listen for{@link AnalysisError analysis errors} being produced by the analysis engine.
 * @coverage dart.engine.error
 */
abstract class AnalysisErrorListener {
  /**
   * This method is invoked when an error has been found by the analysis engine.
   * @param error the error that was just found (not {@code null})
   */
  void onError(AnalysisError error);
}
/**
 * The enumeration {@code StaticTypeWarningCode} defines the error codes used for static type
 * warnings. The convention for this class is for the name of the error code to indicate the problem
 * that caused the error to be generated and for the error message to explain what is wrong and,
 * when appropriate, how the problem can be corrected.
 * @coverage dart.engine.error
 */
class StaticTypeWarningCode implements ErrorCode {
  /**
   * 12.18 Assignment: Let <i>T</i> be the static type of <i>e<sub>1</sub></i>. It is a static type
   * warning if <i>T</i> does not have an accessible instance setter named <i>v=</i>.
   * @see #UNDEFINED_SETTER
   */
  static final StaticTypeWarningCode INACCESSIBLE_SETTER = new StaticTypeWarningCode('INACCESSIBLE_SETTER', 0, "");
  /**
   * 8.1.1 Inheritance and Overriding: However, if there are multiple members <i>m<sub>1</sub>,
   * &hellip; m<sub>k</sub></i> with the same name <i>n</i> that would be inherited (because
   * identically named members existed in several superinterfaces) then at most one member is
   * inherited. If the static types <i>T<sub>1</sub>, &hellip;, T<sub>k</sub></i> of the members
   * <i>m<sub>1</sub>, &hellip;, m<sub>k</sub></i> are not identical, then there must be a member
   * <i>m<sub>x</sub></i> such that <i>T<sub>x</sub> &lt; T<sub>i</sub>, 1 &lt;= x &lt;= k</i> for
   * all <i>i, 1 &lt;= i &lt; k</i>, or a static type warning occurs. The member that is inherited
   * is <i>m<sub>x</sub></i>, if it exists; otherwise:
   * <ol>
   * <li>If all of <i>m<sub>1</sub>, &hellip; m<sub>k</sub></i> have the same number <i>r</i> of
   * required parameters and the same set of named parameters <i>s</i>, then let <i>h = max(
   * numberOfOptionalPositionals( m<sub>i</sub> ) ), 1 &lt;= i &lt;= k</i>. <i>I</i> has a method
   * named <i>n</i>, with <i>r</i> required parameters of type dynamic, <i>h</i> optional positional
   * parameters of type dynamic, named parameters <i>s</i> of type dynamic and return type dynamic.
   * <li>Otherwise none of the members <i>m<sub>1</sub>, &hellip;, m<sub>k</sub></i> is inherited.
   * </ol>
   */
  static final StaticTypeWarningCode INCONSISTENT_METHOD_INHERITANCE = new StaticTypeWarningCode('INCONSISTENT_METHOD_INHERITANCE', 1, "");
  /**
   * 12.18 Assignment: It is a static type warning if the static type of <i>e</i> may not be
   * assigned to the static type of <i>v</i>. The static type of the expression <i>v = e</i> is the
   * static type of <i>e</i>.
   * <p>
   * 12.18 Assignment: It is a static type warning if the static type of <i>e</i> may not be
   * assigned to the static type of <i>C.v</i>. The static type of the expression <i>C.v = e</i> is
   * the static type of <i>e</i>.
   * <p>
   * 12.18 Assignment: Let <i>T</i> be the static type of <i>e<sub>1</sub></i>. It is a static type
   * warning if the static type of <i>e<sub>2</sub></i> may not be assigned to <i>T</i>.
   * @param lhsTypeName the name of the left hand side type
   * @param rhsTypeName the name of the right hand side type
   */
  static final StaticTypeWarningCode INVALID_ASSIGNMENT = new StaticTypeWarningCode('INVALID_ASSIGNMENT', 2, "The type '%s' can't be assigned a '%s'");
  /**
   * 12.14.4 Function Expression Invocation: A function expression invocation <i>i</i> has the form
   * <i>e<sub>f</sub>(a<sub>1</sub>, &hellip; a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>,
   * &hellip;, x<sub>n+k</sub>: a<sub>n+k</sub>)</i>, where <i>e<sub>f</sub></i> is an expression.
   * <p>
   * It is a static type warning if the static type <i>F</i> of <i>e<sub>f</sub></i> may not be
   * assigned to a function type.
   * <p>
   * 12.15.1 Ordinary Invocation: An ordinary method invocation <i>i</i> has the form
   * <i>o.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;
   * x<sub>n+k</sub>: a<sub>n+k</sub>)</i>.
   * <p>
   * Let <i>T</i> be the static type of <i>o</i>. It is a static type warning if <i>T</i> does not
   * have an accessible instance member named <i>m</i>. If <i>T.m</i> exists, it is a static warning
   * if the type <i>F</i> of <i>T.m</i> may not be assigned to a function type. If <i>T.m</i> does
   * not exist, or if <i>F</i> is not a function type, the static type of <i>i</i> is dynamic.
   * <p>
   * 12.15.3 Static Invocation: It is a static type warning if the type <i>F</i> of <i>C.m</i> may
   * not be assigned to a function type.
   * @param nonFunctionIdentifier the name of the identifier that is not a function type
   */
  static final StaticTypeWarningCode INVOCATION_OF_NON_FUNCTION = new StaticTypeWarningCode('INVOCATION_OF_NON_FUNCTION', 3, "'%s' is not a method");
  /**
   * 12.19 Conditional: It is a static type warning if the type of <i>e<sub>1</sub></i> may not be
   * assigned to bool.
   * <p>
   * 13.5 If: It is a static type warning if the type of the expression <i>b</i> may not be assigned
   * to bool.
   * <p>
   * 13.7 While: It is a static type warning if the type of <i>e</i> may not be assigned to bool.
   * <p>
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
  static final StaticTypeWarningCode NON_TYPE_AS_TYPE_ARGUMENT = new StaticTypeWarningCode('NON_TYPE_AS_TYPE_ARGUMENT', 6, "");
  /**
   * 7.6.2 Factories: It is a static type warning if any of the type arguments to <i>k‚Äô</i> are not
   * subtypes of the bounds of the corresponding formal type parameters of type.
   */
  static final StaticTypeWarningCode REDIRECT_WITH_INVALID_TYPE_PARAMETERS = new StaticTypeWarningCode('REDIRECT_WITH_INVALID_TYPE_PARAMETERS', 7, "");
  /**
   * 13.11 Return: It is a static type warning if the type of <i>e</i> may not be assigned to the
   * declared return type of the immediately enclosing function.
   */
  static final StaticTypeWarningCode RETURN_OF_INVALID_TYPE = new StaticTypeWarningCode('RETURN_OF_INVALID_TYPE', 8, "The return type '%s' is not a '%s', as defined by the method");
  /**
   * 12.11 Instance Creation: It is a static type warning if any of the type arguments to a
   * constructor of a generic type <i>G</i> invoked by a new expression or a constant object
   * expression are not subtypes of the bounds of the corresponding formal type parameters of
   * <i>G</i>.
   * @param boundedTypeName the name of the type used in the instance creation that should be
   * limited by the bound as specified in the class declaration
   * @param boundingTypeName the name of the bounding type
   */
  static final StaticTypeWarningCode TYPE_ARGUMENT_NOT_MATCHING_BOUNDS = new StaticTypeWarningCode('TYPE_ARGUMENT_NOT_MATCHING_BOUNDS', 9, "'%s' does not extend '%s'");
  /**
   * 10 Generics: It is a static type warning if a type parameter is a supertype of its upper bound.
   * <p>
   * 15.8 Parameterized Types: If <i>S</i> is the static type of a member <i>m</i> of <i>G</i>, then
   * the static type of the member <i>m</i> of <i>G&lt;A<sub>1</sub>, &hellip; A<sub>n</sub>&gt;</i>
   * is <i>[A<sub>1</sub>, &hellip;, A<sub>n</sub>/T<sub>1</sub>, &hellip;, T<sub>n</sub>]S</i>
   * where <i>T<sub>1</sub>, &hellip; T<sub>n</sub></i> are the formal type parameters of <i>G</i>.
   * Let <i>B<sub>i</sub></i> be the bounds of <i>T<sub>i</sub>, 1 &lt;= i &lt;= n</i>. It is a
   * static type warning if <i>A<sub>i</sub></i> is not a subtype of <i>[A<sub>1</sub>, &hellip;,
   * A<sub>n</sub>/T<sub>1</sub>, &hellip;, T<sub>n</sub>]B<sub>i</sub>, 1 &lt;= i &lt;= n</i>.
   */
  static final StaticTypeWarningCode TYPE_ARGUMENT_VIOLATES_BOUNDS = new StaticTypeWarningCode('TYPE_ARGUMENT_VIOLATES_BOUNDS', 10, "");
  /**
   * 12.17 Getter Invocation: Let <i>T</i> be the static type of <i>e</i>. It is a static type
   * warning if <i>T</i> does not have a getter named <i>m</i>.
   */
  static final StaticTypeWarningCode UNDEFINED_GETTER = new StaticTypeWarningCode('UNDEFINED_GETTER', 11, "There is no such getter '%s' in '%s'");
  /**
   * 12.18 Assignment: Let <i>T</i> be the static type of <i>e<sub>1</sub></i>. It is a static type
   * warning if <i>T</i> does not have an accessible instance setter named <i>v=</i>.
   * @see #INACCESSIBLE_SETTER
   */
  static final StaticTypeWarningCode UNDEFINED_SETTER = new StaticTypeWarningCode('UNDEFINED_SETTER', 12, "There is no such setter '%s' in '%s'");
  /**
   * 12.15.4 Super Invocation: A super method invocation <i>i</i> has the form
   * <i>super.m(a<sub>1</sub>, &hellip;, a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;
   * x<sub>n+k</sub>: a<sub>n+k</sub>)</i>. It is a static type warning if <i>S</i> does not have an
   * accessible instance member named <i>m</i>.
   * @param methodName the name of the method that is undefined
   * @param typeName the resolved type name that the method lookup is happening on
   */
  static final StaticTypeWarningCode UNDEFINED_SUPER_METHOD = new StaticTypeWarningCode('UNDEFINED_SUPER_METHOD', 13, "There is no such method '%s' in '%s'");
  /**
   * 15.8 Parameterized Types: It is a static type warning if <i>G</i> is not an accessible generic
   * type declaration with <i>n</i> type parameters.
   * @param typeName the name of the type being referenced (<i>G</i>)
   * @param argumentCount the number of type arguments provided
   * @param parameterCount the number of type parameters that were declared
   */
  static final StaticTypeWarningCode WRONG_NUMBER_OF_TYPE_ARGUMENTS = new StaticTypeWarningCode('WRONG_NUMBER_OF_TYPE_ARGUMENTS', 14, "The type '%s' is declared with %d type parameters, but %d type arguments were given");
  static final List<StaticTypeWarningCode> values = [INACCESSIBLE_SETTER, INCONSISTENT_METHOD_INHERITANCE, INVALID_ASSIGNMENT, INVOCATION_OF_NON_FUNCTION, NON_BOOL_CONDITION, NON_BOOL_EXPRESSION, NON_TYPE_AS_TYPE_ARGUMENT, REDIRECT_WITH_INVALID_TYPE_PARAMETERS, RETURN_OF_INVALID_TYPE, TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, TYPE_ARGUMENT_VIOLATES_BOUNDS, UNDEFINED_GETTER, UNDEFINED_SETTER, UNDEFINED_SUPER_METHOD, WRONG_NUMBER_OF_TYPE_ARGUMENTS];
  final String __name;
  final int __ordinal;
  int get ordinal => __ordinal;
  /**
   * The message template used to create the message to be displayed for this error.
   */
  String _message;
  /**
   * Initialize a newly created error code to have the given type and message.
   * @param message the message template used to create the message to be displayed for the error
   */
  StaticTypeWarningCode(this.__name, this.__ordinal, String message) {
    this._message = message;
  }
  ErrorSeverity get errorSeverity => ErrorType.STATIC_TYPE_WARNING.severity;
  String get message => _message;
  ErrorType get type => ErrorType.STATIC_TYPE_WARNING;
  bool needsRecompilation() => true;
  String toString() => __name;
}