package com.google.dart.compiler.parser;

import com.google.dart.compiler.ErrorCode;
import com.google.dart.compiler.ErrorSeverity;
import com.google.dart.compiler.SubSystem;

/**
 * {@link ErrorCode}s for parser.
 */
public enum ParserErrorCode implements ErrorCode {
  ABSTRACT_MEMBER_IN_INTERFACE("Abstract members are not allowed in interfaces"),
  CATCH_OR_FINALLY_EXPECTED("catch or finally clause expected."),
  DEFAULT_POSITIONAL_PARAMETER("Positional parameters cannot have default values"),
  DISALLOWED_ABSTRACT_KEYWORD("Abstract keyword not allowed here"),
  DISALLOWED_FACTORY_KEYWORD("Factory keyword not allowed here"),
  EXPECTED_ARRAY_OR_MAP_LITERAL("Expected array or map literal"),
  EXPECTED_CASE_OR_DEFAULT("Expected 'case' or 'default'"),
  EXPECTED_CLASS_DECLARATION_LBRACE("Expected '{' in class or interface declaration"),
  EXPECTED_COMMA_OR_RIGHT_BRACE("Expected ',' or '}'"),
  EXPECTED_COMMA_OR_RIGHT_PAREN("Expected ',' or ')', but got '%s'"),
  EXPECTED_EOS("Unexpected token '%s' (expected end of file)"),
  EXPECTED_IDENTIFIER("Expected identifier"),
  EXPECTED_LEFT_PAREN("'(' expected"),
  EXPECTED_PERIOD_OR_LEFT_BRACKET("Expected '.' or '['"),
  EXPECTED_PREFIX_KEYWORD("Expected 'prefix' after comma"),
  EXPECTED_PREFIX_IDENTIFIER("Prefix string can only contain valid identifier characters"),
  EXPECTED_SEMICOLON("Expected ';'"),
  EXPECTED_STRING_LITERAL("Expected string literal"),
  EXPECTED_TOKEN("Unexpected token '%s' (expected '%s')"),
  EXPECTED_VAR_FINAL_OR_TYPE("Expected 'var', 'final' or type"),
  EXPORTED_FUNCTIONS_MUST_BE_STATIC("Exported functions must be static"),
  EXTENDED_NATIVE_CLASS("Native classes must not extend other classes"),
  FACTORY_CANNOT_BE_ABSTRACT("A factory cannot be abstract"),
  FACTORY_CANNOT_BE_STATIC("A factory cannot be static"),
  FACTORY_MEMBER_IN_INTERFACE("Factory members are not allowed in interfaces"),
  FOR_IN_WITH_COMPLEX_VARIABLE("Only simple variables can be assigned to in a for-in construct"),
  FOR_IN_WITH_MULTIPLE_VARIABLES("Too many variable declarations in a for-in construct"),
  FOR_IN_WITH_VARIABLE_INITIALIZER("Cannot initialize for-in variables"),
  FUNCTION_TYPED_PARAMETER_IS_FINAL("Formal parameter with a function type cannot be const"),
  FUNCTION_TYPED_PARAMETER_IS_VAR("Formal parameter with a function type cannot be var"),
  ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE("Illegal assignment to non-assignable expression"),
  ILLEGAL_NUMBER_OF_ARGUMENTS("Illegal number of arguments"),
  INCOMPLETE_STRING_LITERAL("Incomplete string literal"),
  INVALID_FIELD_DECLARATION("Wrong syntax for field declaration"),
  INVALID_OPERATOR_CHAINING("Cannot chain '%s'"),
  MISSING_FUNCTION_NAME("a function name is required for a declaration"),
  NON_FINAL_STATIC_MEMBER_IN_INTERFACE("Non-final static members are not allowed in interfaces"),
  OPERATOR_CANNOT_BE_STATIC("Operators cannot be static"),
  TOP_LEVEL_IS_STATIC("Top-level field or method may not be static"),
  UNEXPECTED_TOKEN("Unexpected token '%s'"),
  UNEXPECTED_TOKEN_IN_STRING_INTERPOLATION("Unexpected token in string interpolation: %s"),
  UNEXPECTED_TYPE_ARGUMENT("unexpected type argument"),
  VOID_FIELD("Field cannot be of type void"),
  VOID_PARAMETER("Parameter cannot be of type void");
  private final ErrorSeverity severity;
  private final String message;

  /**
   * Initialize a newly created error code to have the given message and ERROR severity.
   */
  private ParserErrorCode(String message) {
    this(ErrorSeverity.ERROR, message);
  }

  /**
   * Initialize a newly created error code to have the given severity and message.
   */
  private ParserErrorCode(ErrorSeverity severity, String message) {
    this.severity = severity;
    this.message = message;
  }

  public String getMessage() {
    return message;
  }

  public ErrorSeverity getErrorSeverity() {
    return severity;
  }

  public SubSystem getSubSystem() {
    return SubSystem.PARSER;
  }
}