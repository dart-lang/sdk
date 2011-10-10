// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

/**
 * Valid error codes for the errors produced by the Dart compiler.
 */
public enum DartCompilerErrorCode implements ErrorCode {
  // TODO(brianwilkerson) Fill in the error messages as error creation sites are converted to use
  // these error codes.
  ABSTRACT_CLASS("%s is an abstract class because it does not implement the following members:%s"),
  ABSTRACT_MEMBER_IN_INTERFACE("SyntaxError: abstract members are not allowed in interfaces"),
  CANNOT_ACCESS_OUTER_LABEL("Cannot access label %s declared in an outer function"),
  CANNOT_ACCESS_FIELD_IN_INIT("Cannot access an instance field in an initializer expression"),
  CANNOT_ASSIGN_TO_FINAL("cannot assign value to final variable \"%s\"."),
  CANNOT_BE_RESOLVED("cannot resolve %s"),
  CANNOT_BE_RESOLVED_LIBRARY("cannot resolve %s in library %s"),
  CANNOT_BE_INITIALIZED("cannot be initialized"),
  CANNOT_CALL_LABEL("Labels cannot be called"),
  CANNOT_DECLARE_NON_FACTORY_CONSTRUCTOR(
      "Cannot declare a non-factory named constructor of another class."),
  CANNOT_INIT_FIELD_FROM_SUPERCLASS("Cannot initialize a field from a super class"),
  CANNOT_INIT_STATIC_FIELD_IN_INITIALIZER(
      "Cannot initialize a static field in an initializer list"),
  CANNOT_INSTATIATE_ABSTRACT_CLASS("cannot instantiate abstract class %s"),
  CANNOT_OVERRIDE_INSTANCE_MEMBER("static member cannot override instance member %s of %s"),
  CANNOT_OVERRIDE_STATIC_MEMBER("cannot override static member %s of %s"),
  CANNOT_OVERRIDE_TYPED_MEMBER("cannot override %s of %s because %s is not assignable to %s"),
  CANNOT_RESOLVE_CONSTRUCTOR("cannot resolve constructor %s"),
  CANNOT_RESOLVE_FIELD("cannot resolve field %s"),
  CANNOT_RESOLVE_LABEL("cannot resolve label %s"),
  CANNOT_RESOLVE_METHOD("cannot resolve method %s"),
  CANNOT_RESOLVE_SUPER_CONSTRUCTOR("cannot resolve method %s"),
  CANNOT_RESOLVE_IMPLICIT_CALL_TO_SUPER_CONSTRUCTOR(
      "super type %s does not have a default constructor"),
  CATCH_OR_FINALLY_EXPECTED("catch or finally clause expected."),
  CONSTRUCTOR_CANNOT_BE_ABSTRACT("A constructor cannot be asbstract"),
  CONSTRUCTOR_CANNOT_BE_STATIC("A constructor cannot be static"),
  CONSTRUCTOR_MUST_CALL_SUPER("Constructors must call super constructor"),
  CONST_CONSTRUCTOR_CANNOT_HAVE_BODY("A cconst onstructor cannot have a body"),
  CONST_CONSTRUCTOR_MUST_CALL_CONST_SUPER("const constructor must call const super constructor"),
  CONSTANTS_MUST_BE_INITIALIZED("constants must be initialized"),
  CYCLIC_CLASS("%s causes a cycle in the supertype graph"),
  DEFAULT_POSITIONAL_PARAMETER("Positional parameters cannot have default values"),
  DID_YOU_MEAN_NEW("%1$s is a %2$s. Did you mean (new %1$s)?"),
  DISALLOWED_ABSTRACT_KEYWORD("SyntaxError: abstract keyword not allowed here"),
  DISALLOWED_FACTORY_KEYWORD("SyntaxError: factory keyword not allowed here"),
  DUPLICATE_DEFINITION("duplicate definition of %s"),
  DUPLICATED_INTERFACE("%s and %s are duplicated in the supertype graph"),
  ENTRY_POINT_IN_LIBRARY("Libraries may not specify an entry point"),
  ENTRY_POINT_METHOD_CANNOT_HAVE_PARAMETERS("Main entry point method cannot have parameters"),
  ENTRY_POINT_METHOD_MAY_NOT_BE_GETTER("Entry point \"%s\" may not be a getter"),
  ENTRY_POINT_METHOD_MAY_NOT_BE_SETTER("Entry point \"%s\" may not be a setter"),
  EXPECTED_AN_INSTANCE_FIELD_IN_SUPER_CLASS(
      "expected an instance field in the super class, but got %s"),
  EXPECTED_ARRAY_OR_MAP_LITERAL("Expected array or map literal"),
  EXPECTED_CASE_OR_DEFAULT("Expected 'case' or 'default'"),
  EXPECTED_COMMA_OR_RIGHT_BRACE("Expected ',' or '}'"),
  EXPECTED_COMMA_OR_RIGHT_PAREN("Expected ',' or ')', but got '%s'"),
  EXPECTED_COMPOUND_STATEMENT("SyntaxError: expected if, switch, while, do, or for"),
  EXPECTED_CONSTANT_LITERAL("Expected a constant literal"),
  EXPECTED_EOS("Unexpected token '%s' (expected end of file)"),
  EXPECTED_FIELD_NOT_CLASS("%s is a class, expected a local field"),
  EXPECTED_FIELD_NOT_METHOD("%s is a method, expected a local field"),
  EXPECTED_FIELD_NOT_PARAMETER("%s is a parameter, expected a local field"),
  EXPECTED_FIELD_NOT_TYPE_VAR("%s is a type variable, expected a local field"),
  EXPECTED_IDENTIFIER("Expected identifier"),
  EXPECTED_ONE_ARGUMENT("Expected one argument"),
  EXPECTED_LEFT_BRACKET_OR_LEFT_BRACE("'[' or '{' expected"),
  EXPECTED_LEFT_PAREN("'(' expected"),
  EXPECTED_LIBRARY("Must begin with 'library' or 'application'"),
  EXPECTED_PERIOD_OR_LEFT_BRACKET("SyntaxError: expected '.' or '['"),
  EXPECTED_PREFIX_KEYWORD("SyntaxError: expected 'prefix' after comma"),
  EXPECTED_SEMICOLON("Expected ';'"),
  EXPECTED_STATIC_FIELD("expected a static field, but got %s"),
  EXPECTED_STRING_LITERAL("Expected string literal"),
  EXPECTED_TYPE("Expected type %s, got %s"),
  EXPECTED_TOKEN("Unexpected token '%s' (expected '%s')"),
  EXPECTED_VAR_FINAL_OR_TYPE("Expected 'var', 'final' or type"),
  EXPORTED_FUNCTIONS_MUST_BE_STATIC("Exported functions must be static"),
  EXTENDED_NATIVE_CLASS("Native classes must not extend other classes"),
  EXTRA_ARGUMENT("extra argument"),
  EXTRA_COMMA("Extra comma"),
  EXTRA_QUALIFIER_FOR_TYPE_DECLARATION("SyntaxError: extra qualifier for a class or interface "
      + "definition"),
  EXTRA_TYPE_ARGUMENT("Type variables may not have type arguments"),
  FACTORY_ACCESS_SUPER("Cannot use 'super' in a factory constructor"),
  FACTORY_CANNOT_BE_ABSTRACT("SyntaxError: A factory cannot be abstract"),
  FACTORY_CANNOT_BE_CONST("SyntaxError: A factory cannot be const"),
  FACTORY_CANNOT_BE_STATIC("SyntaxError: A factory cannot be static"),
  FACTORY_MEMBER_IN_INTERFACE("SyntaxError: factory members are not allowed in interfaces"),
  FIELD_CONFLICTS("%s conflicts with previously defined %s at line %d column %d"),
  FOR_IN_WITH_COMPLEX_VARIABLE("Only simple variables can be assigned to in a for-in construct"),
  FOR_IN_WITH_MULTIPLE_VARIABLES("Too many variable declarations in a for-in construct"),
  FOR_IN_WITH_VARIABLE_INITIALIZER("Cannot initialize for-in variables"),
  FUNCTION_KEYWORD("'function' keyword is deprecated'"),
  FUNCTION_TYPED_PARAMETER_IS_CONST("Formal parameter with a function type cannot be const"),
  FUNCTION_TYPED_PARAMETER_IS_FINAL("Formal parameter with a function type cannot be const"),
  FUNCTION_TYPED_PARAMETER_IS_VAR("Formal parameter with a function type cannot be var"),
  FUNCTION_TYPED_PARAMETER_IS_VARIADIC("Formal parameter with a function type cannot be variadic"),
  ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE("SyntaxError: Illegal assignment to non-assignable "
      + "expression"),
  ILLEGAL_DIRECTIVES_IN_SOURCED_UNIT("A source which was included by another source via a "
      + "#source directive cannot itself contain directives: %s -> %s"),
  ILLEGAL_FIELD_ACCESS_FROM_STATIC("Illegal access of instance field %s from static scope"),
  ILLEGAL_METHOD_ACCESS_FROM_STATIC("Illegal access of instance method %s from static scope"),
  ILLEGAL_NUMBER_OF_ARGUMENTS("SyntaxError: Illegal number of arguments"),
  INCOMPLETE_STRING_LITERAL("Incomplete string literal"),
  INSTANCE_METHOD_FROM_STATIC("Instance methods cannot be referenced from static methods"),
  INTERFACE_HAS_NO_METHOD_NAMED("%s has no method named \"%s\""),
  INTERNAL_ERROR("internal error: %s"),
  INVALID_FIELD_DECLARATION("SyntaxError: wrong syntax for field declaration"),
  INVALID_OPERATOR_CHAINING("SyntaxError: cannot chain '%s'"),
  INVALID_TYPE_NAME_IN_CONSTRUCTOR("Invalid type in constructor name"),
  IS_A_CLASS("%s is a class and cannot be used as an expression"),
  IS_A_CONSTRUCTOR("%s.%s is a constructor, expected a  method"),
  IS_AN_INSTANCE_METHOD("%s.%s is an instance method, not a static method"),
  IS_STATIC_FIELD_IN("\"%s\" is a static field in \"%s\""),
  IS_STATIC_METHOD_IN("\"%s\" is a static method in \"%s\""),
  MALFORMED_FUNCTION_TYPE_ALIAS("SyntaxError: malformed function alias"),
  MALFORMED_PARAMETERIZED_TYPE("SyntaxError: malformed parameterized type"),
  MEMBER_IS_A_CONSTRUCTOR("%s is a constructor in %s"),
  METHOD_MUST_HAVE_BODY("A non-abstract method must have a body"),
  MISSING_ARGUMENT("missing argument of type %s"),
  MISSING_FUNCTION_NAME("a function name is required for a declaration"),
  MISSING_LIBRARY_DIRECTIVE("a library which was imported into another library is missing a "
      + "#library directive: %s"),
  MISSING_RETURN_VALUE("no return value; expected a value of type %s"),
  MISSING_SOURCE("Cannot find referenced source: %s"),
  MULTIPLE_ENTRY_POINTS("'entrypoint' may be specified only once"),
  MULTIPLE_IMPORT_LISTS("'import' may be specified only once"),
  MULTIPLE_NATIVES("'native' may be specified only once"),
  MULTIPLE_RESOURCE_LISTS("'resource' may be specified only once"),
  MULTIPLE_REST_PARAMETERS("multiple rest parameters"),
  MULTIPLE_SOURCE_LISTS("'source' may be specified only once"),
  NAMED_AND_VARIADIC_PARAMETERS("Cannot have both named and variadic parameters"),
  NAME_CLASHES_EXISTING_MEMBER(
      "name clashes with a previously defined member at %sline %d column %d"),
  NEW_EXPRESSION_NOT_CONSTRUCTOR("New expression does not resolve to a constructor"),
  NEW_EXPRESSION_CANT_USE_TYPE_VAR("New expression cannot be invoked on type variable"),
  NON_CONST_STATIC_MEMBER_IN_INTERFACE("SyntaxError: non-final static members are not allowed in "
      + "interfaces"),
  NON_FINAL_STATIC_MEMBER_IN_INTERFACE("SyntaxError: non-final static members are not allowed in "
      + "interfaces"),
  NO_SUCH_TYPE("no such type \"%s\""),
  NO_ENTRY_POINT("No entrypoint specified for app"),
  NOT_A_CLASS("\"%s\" is not a class"),
  NOT_A_CLASS_OR_INTERFACE("\"%s\" is not a class or interface"),
  NOT_A_LABEL("\"%s\" is not a label"),
  NOT_A_MEMBER_OF("\"%s\" is not a member of %s"),
  NOT_A_METHOD_IN("\"%s\" is not a method in %s"),
  NOT_AN_INSTANCE_FIELD("%s is not an instance field"),
  NOT_AN_INTERFACE("\"%s\" is not an interface"),
  NOT_A_FUNCTION("\"%s\" is not a function"),
  NOT_A_STATIC_FIELD("\"%s\" is not a static field"),
  NOT_A_STATIC_METHOD("\"%s\" is not a static method"),
  REDIRECTED_CONSTRUCTOR_CYCLE("Redirected constructor call has a cycle."),
  OPERATOR_CANNOT_BE_STATIC("SyntaxError: Operators cannot be static"),
  OPERATOR_WRONG_OPERAND_TYPE("operand of \"%s\" must be assignable to \"%s\""),
  PARAMETER_INIT_OUTSIDE_CONSTRUCTOR("Parameter initializers can only be used in constructors"),
  PARAMETER_INIT_STATIC_FIELD(
      "Parameter initializer cannot be use to initialize a static field '%s'"),
  PARAMETER_INIT_WITH_REDIR_CONSTRUCTOR(
      "Parameter initializers cannot be used with redirected constructors"),
  PARAMETER_NOT_MATCH_FIELD("Could not match parameter initializer '%s' with any field"),
  STATIC_FINAL_REQUIRES_VALUE("Static final fields must have an initial value"),
  STATIC_MEMBER_ACCESSED_THROUGH_INSTANCE(
      "static member %s of %s cannot be accessed through an instance"),
  STATIC_METHOD_ACCESS_SUPER("Cannot use 'super' in a static method"),
  STATIC_METHOD_ACCESS_THIS("Cannot use 'this' in a static method"),
  SUPERFLUOUS_FUNCTION_KEYWORD("SyntaxError: superfluous 'function' keyword"),
  SUPER_CALL_MUST_BE_FIRST("super call must be first in initializer list"),
  SUPER_OUTSIDE_OF_METHOD("Cannot use 'super' outside of a method"),
  SUPERTYPE_HAS_FIELD("%s is a field in %s"),
  SUPERTYPE_HAS_METHOD("%s is a method in %s"),
  TOP_LEVEL_IS_STATIC("Top-level field or method may not be static"),
  TOP_LEVEL_METHOD_ACCESS_SUPER("Cannot use 'super' in a top-level method"),
  TOP_LEVEL_METHOD_ACCESS_THIS("Cannot use 'this' in a top-level method"),
  TYPE_NOT_ASSIGNMENT_COMPATIBLE("%s is not assignable to %s"),
  TYPE_VARIABLE_IN_STATIC_CONTEXT("cannot access type variable %s in static context"),
  UNEXPECTED_TOKEN("Unexpected token '%s'"),
  UNEXPECTED_TOKEN_IN_STRING_INTERPOLATION("Unexpected token in string interpolation: %s"),
  UNEXPECTED_TYPE_ARGUMENT("unexpected type argument"),
  UNREFERENCED_LABEL("unreferenced label \"%s\""),
  USELESS_LABEL("useless label \"%s\""),
  VOID("expression does not yield a value"),
  VOID_CANNOT_RETURN_VALUE("cannot return a value from a void function"),
  VOID_FIELD("SyntaxError: field cannot be of type void"),
  VOID_PARAMETER("SyntaxError: parameter cannot be of type void"),
  VOID_VARIABLE("Variable cannot be of type void"),
  WRONG_NUMBER_OF_TYPE_ARGUMENTS("%s: wrong number of type arguments");

  /**
   * The message format string used to create the message to be displayed for this error.
   */
  private String message;

  private DartCompilerErrorCode() {
    // TODO(brianwilkerson) Remove this constructor once all of the error codes have messages
    // associated with them.
    this("%s");
  }

  /**
   * Initialize a newly created error code to have the given message.
   *
   * @param message the message format string used to create the message to be displayed for this
   *        error
   */
  private DartCompilerErrorCode(String message) {
    this.message = message;
  }

  @Override
  public String getMessage() {
    return message;
  }
}
