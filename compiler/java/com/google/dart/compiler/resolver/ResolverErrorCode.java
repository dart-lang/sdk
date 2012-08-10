// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler.resolver;

import com.google.dart.compiler.ErrorCode;
import com.google.dart.compiler.ErrorSeverity;
import com.google.dart.compiler.SubSystem;

/**
 * {@link ErrorCode}s for resolver.
 */
public enum ResolverErrorCode implements ErrorCode {
  BLACK_LISTED_EXTENDS("'%s' can not be used as superclass"),
  BLACK_LISTED_IMPLEMENTS("'%s' can not be used as superinterface"),
  BREAK_LABEL_RESOLVES_TO_CASE_OR_DEFAULT("break label resolves to case or default statement"),
  BUILT_IN_IDENTIFIER_AS_IMPORT_PREFIX("Build-in identifier '%s' cannot be used as a import prefix"),
  BUILT_IN_IDENTIFIER_AS_TYPE("Build-in identifier '%s' cannot be used as a type annotation"),
  CANNOT_ACCESS_FIELD_IN_INIT("Cannot access an instance field in an initializer expression"),
  CANNOT_ACCESS_METHOD(ErrorSeverity.WARNING, "Cannot access private method '%s'"),
  CANNOT_ACCESS_OUTER_LABEL("Cannot access label %s declared in an outer function"),
  CANNOT_ASSIGN_TO_FINAL("cannot assign value to final variable \"%s\"."),
  CANNOT_ASSIGN_TO_METHOD("cannot assign value to method '%s'."),
  CANNOT_BE_RESOLVED("cannot resolve %s"),
  // TODO(zundel): error message needs JUnit test - how to test #imports in junit?
  CANNOT_BE_RESOLVED_LIBRARY("cannot resolve %s in library %s"),
  CANNOT_CALL_FUNCTION_TYPE_ALIAS("Function type aliases cannot be called"),
  // TODO(zundel): error message needs JUnit test - how to test #imports in junit?
  CANNOT_CALL_LIBRARY_PREFIX("Library prefixes cannot be called"),
  CANNOT_DECLARE_NON_FACTORY_CONSTRUCTOR(ErrorSeverity.WARNING,
      "Cannot declare a non-factory named constructor of another class."),
  CANNOT_HIDE_IMPORT_PREFIX("Cannot hide import prefix '%s'"),
  CANNOT_INIT_STATIC_FIELD_IN_INITIALIZER("Cannot initialize a static field in an initializer list"),
  CANNOT_OVERRIDE_INSTANCE_MEMBER("static member cannot override instance member %s of %s"),
  CANNOT_OVERRIDE_METHOD_NUM_REQUIRED_PARAMS(
      "cannot override method %s from %s, wrong number of required parameters"),
  CANNOT_OVERRIDE_METHOD_NAMED_PARAMS(
      "cannot override method %s, named parameters don't match"),
  CANNOT_RESOLVE_CONSTRUCTOR("cannot resolve constructor %s"),
  CANNOT_RESOLVE_FIELD("cannot resolve field %s"),
  CANNOT_RESOLVE_LABEL("cannot resolve label %s"),
  CANNOT_RESOLVE_METHOD("cannot resolve method '%s'"),
  CANNOT_RESOLVE_METHOD_IN_CLASS("cannot resolve method '%s' in class '%s'"),
  // TODO(zundel): error message needs JUnit test - how to test #imports in junit?
  CANNOT_RESOLVE_METHOD_IN_LIBRARY("cannot resolve method '%s' in library '%s'"),
  // TODO(zundel): To exercise this requires simulating a corrupted SDK?
  CANNOT_RESOLVE_SDK_TYPE("cannot resolve SDK type %s"),
  CANNOT_RESOLVE_SUPER_CONSTRUCTOR("cannot resolve method '%s'"),
  CANNOT_RESOLVE_IMPLICIT_CALL_TO_SUPER_CONSTRUCTOR(
      "super type %s does not have a default constructor"),
  CANNOT_USE_INSTANCE_FIELD_IN_INSTANCE_FIELD_INITIALIZER(
      "Cannot use instance field in instance field initializer"),
  CANNOT_USE_THIS_IN_INSTANCE_FIELD_INITIALIZER("Cannot use 'this' in instance field initializer"),
  CANNOT_USE_TYPE("Cannot reference the type '%s' in this context"),
  // TODO(zundel): error message needs JUnit test (reachable code?)
  CANNOT_USE_TYPE_VARIABLE("Cannot reference the type variable '%s' in this context"),
  CIRCULAR_REFERENCE(
      "Circular reference detected:  compile-time constants cannot reference themselves."),
  CONST_REQUIRES_VALUE("Constant fields must have an initial value"),
  CONSTRUCTOR_CANNOT_BE_ABSTRACT("A constructor cannot be asbstract"),
  CONSTRUCTOR_CANNOT_BE_STATIC("A constructor cannot be static"),
  CONSTRUCTOR_CANNOT_HAVE_RETURN_TYPE("Generative constructors cannot have return type"),
  CONST_AND_NONCONST_CONSTRUCTOR("Cannot reference to non-const constructor."),
  CONST_ARRAY_WITH_TYPE_VARIABLE("Const array literals cannot have a type variable as a type argument"),
  CONST_CLASS_WITH_INHERITED_NONFINAL_FIELDS(
      "Const class %s cannot have non-final, inherited field %s from class %s"),
  CONST_CLASS_WITH_NONFINAL_FIELDS("Const class %s cannot have non-final field %s"),
  CONST_CONSTRUCTOR_CANNOT_HAVE_BODY("A const constructor cannot have a body"),
  CONST_CONSTRUCTOR_MUST_CALL_CONST_SUPER("const constructor must call const super constructor"),
  CONST_MAP_WITH_TYPE_VARIABLE("Const map literals cannot have a type variable as a type argument"),
  CONST_WITH_TYPE_VARIABLE("Const constructor cannot be invoked with a type variable as a type argument"),
  CONSTANTS_MUST_BE_INITIALIZED("constants must be initialized"),
  CONTINUE_LABEL_RESOLVES_TO_SWITCH("continue label resolves to switch, must be loop or switch member"),
  CYCLIC_CLASS("%s causes a cycle in the supertype graph"),
  DEFAULT_CLASS_MUST_HAVE_SAME_TYPE_PARAMS(
      "default class must have the same type parameters as declared in the interface"),
  DEFAULT_CONSTRUCTOR_UNRESOLVED("Cannot resolve constructor with name '%s' in default class '%s'"),
  DEFAULT_CONSTRUCTOR_NUMBER_OF_REQUIRED_PARAMETERS(
      "Constructor '%s' in '%s' has %s required parameters, doesn't match '%s' in '%s' with %s"),
  DEFAULT_CONSTRUCTOR_NAMED_PARAMETERS(
      "Constructor '%s' in '%s' has named parameters %s, doesn't match '%s' in '%s' with %s"),
  DEFAULT_MUST_SPECIFY_CLASS("default must indicate a class, not an interface"),
  DEPRECATED_MAP_LITERAL_SYNTAX(ErrorSeverity.WARNING,
      "Deprecated Map literal syntax. Only specify a single value type as a type argument."),
  DID_YOU_MEAN_NEW("%1$s is a %2$s. Did you mean (new %1$s)?"),
  DUPLICATE_INITIALIZATION("Duplicate initialization of '%s'"),
  DUPLICATE_FUNCTION_EXPRESSION("Duplicate function expression '%s'"),
  DUPLICATE_FUNCTION_EXPRESSION_WARNING(ErrorSeverity.WARNING,
      "Function expression '%s' is hiding %s at %s"),
  DUPLICATE_LABEL_IN_SWITCH_STATEMENT("Duplicate label in switch statement"),
  DUPLICATE_LOCAL_VARIABLE_ERROR("Duplicate local variable '%s'"),
  DUPLICATE_LOCAL_VARIABLE_WARNING(ErrorSeverity.WARNING,
      "Local variable '%s' is hiding %s at %s"),
  DUPLICATE_MEMBER("Duplicate member '%s'"),
  DUPLICATE_NAMED_ARGUMENT("Duplicate named parameter argument"),
  DUPLICATE_PARAMETER("Duplicate parameter '%s'"),
  DUPLICATE_PARAMETER_WARNING(ErrorSeverity.WARNING, "Parameter '%s' is hiding %s at %s"),
  DUPLICATE_TOP_LEVEL_DECLARATION("duplicate top-level declaration %s at %s"),
  DUPLICATE_TYPE_VARIABLE("Duplicate type variable '%s'"),
  DUPLICATE_TYPE_VARIABLE_WARNING(ErrorSeverity.WARNING, "Type variable '%s' is hiding %s at %s"),
  // TODO(zundel): error message needs JUnit test, (reachable code?)
  EXPECTED_AN_INSTANCE_FIELD_IN_SUPER_CLASS(
      "expected an instance field in the super class, but got %s"),
  EXPECTED_CONSTANT_EXPRESSION("Expected constant expression"),
  EXPECTED_CONSTANT_EXPRESSION_BOOLEAN("Expected constant expression of type bool, got %s"),
  EXPECTED_CONSTANT_EXPRESSION_INT("Expected constant expression of type int, got %s"),
  EXPECTED_CONSTANT_EXPRESSION_STRING("Expected constant expression of type String, got %s"),
  EXPECTED_CONSTANT_EXPRESSION_NUMBER("Expected constant expression of type num, got %s"),
  EXPECTED_CONSTANT_EXPRESSION_STRING_NUMBER_BOOL(
      "Expected constant expression of type String, num or bool, got %s"),
  EXPECTED_FIELD_NOT_CLASS("%s is a class, expected a local field"),
  EXPECTED_FIELD_NOT_METHOD("%s is a method, expected a local field"),
  EXPECTED_FIELD_NOT_PARAMETER("%s is a parameter, expected a local field"),
  EXPECTED_FIELD_NOT_TYPE_VAR("%s is a type variable, expected a local field"),
  // TODO(zundel): error message needs JUnit test (reachable code?)
  EXPECTED_STATIC_FIELD("expected a static field, but got %s"),
  // TODO(zundel): error message needs JUnit test, (reachable code?)
  EXTRA_TYPE_ARGUMENT("Type variables may not have type arguments"),
  FACTORY_CANNOT_BE_CONST("A factory cannot be const"),
  FIELD_DOES_NOT_HAVE_A_GETTER("Field does not have a getter"),
  FIELD_DOES_NOT_HAVE_A_SETTER("Field does not have a setter"),
  FIELD_GETTER_SETTER_SAME_STATIC("Field's getter and setter should be both static or not static"),
  FINAL_FIELD_MUST_BE_INITIALIZED("The final field %s must be initialized"),
  // TODO(zundel): error message needs JUnit test - how to test #imports in junit?
  ILLEGAL_ACCESS_TO_PRIVATE("'%s' is private and not defined in this library"),
  // TODO(zundel): error message needs JUnit test - how to test #imports in junit?
  ILLEGAL_ACCESS_TO_PRIVATE_MEMBER("\"%s\" refers to \"%s\" which is in a different library"),
  ILLEGAL_CONSTRUCTOR_NO_DEFAULT_IN_INTERFACE(
      "Illegal constructor declaration.  No default clause in interface"),
  ILLEGAL_FIELD_ACCESS_FROM_STATIC("Illegal access of instance field %s from static scope"),
  ILLEGAL_METHOD_ACCESS_FROM_STATIC("Illegal access of instance method %s from static scope"),
  INIT_FIELD_ONLY_IMMEDIATELY_SURROUNDING_CLASS(
      "Only fields of immediately surrounding class can be initialized"),
  INSTANCE_METHOD_FROM_INITIALIZER("Instance methods cannot be referenced from constructor initializer"),
  INSTANCE_METHOD_FROM_REDIRECT("Instance methods cannot be referenced from constructor redirects"),
  INSTANCE_METHOD_FROM_STATIC("Instance methods cannot be referenced from static methods"),
  INTERNAL_ERROR("internal error: %s"),
  INVALID_OVERRIDE_METADATA(ErrorSeverity.INFO, "Method marked with @override, but does not override any superclass element"),
  INVALID_RETURN_IN_CONSTRUCTOR("Generative constructors cannot return arbitrary expressions"),
  // TODO(zundel): error message needs JUnit test (reachable code?)
  INVALID_TYPE_NAME_IN_CONSTRUCTOR("Invalid type in constructor name"),
  IS_A_CLASS("%s is a class and cannot be used as an expression"),
  // TODO(zundel): error message needs JUnit test (reachable code?)
  IS_A_CONSTRUCTOR("%s.%s is a constructor, expected a  method"),
  IS_AN_INSTANCE_FIELD("%s.%s is an instance field, not a static method"),
  IS_AN_INSTANCE_METHOD("%s.%s is an instance method, not a static method"),
  // TODO(zundel): error message needs JUnit test (requires development mode checks)
  LIST_LITERAL_ELEMENT_TYPE(
      "List literal element type must match declaration '%s' when type checks are on."),
  MAIN_FUNCTION_PARAMETERS(
      ErrorSeverity.WARNING, "Top-level function 'main' should not have parameters."),
  // TODO(zundel): error message needs JUnit test (requires development mode checks)
  MAP_LITERAL_ELEMENT_TYPE(
      "Map literal element type must match declaration '%s' when type checks are on."),
  MEMBER_WITH_NAME_OF_CLASS("Class member should not have the same name as the enclosing class"),
  METHOD_MUST_HAVE_BODY("A non-abstract method must have a body"),
  NAMED_PARAMETERS_CANNOT_START_WITH_UNDER("Named parameters cannot start with an '_' character"),
  NEW_EXPRESSION_CANT_USE_TYPE_VAR("New expression cannot be invoked on type variable"),
  NEW_EXPRESSION_NOT_CONSTRUCTOR(
      ErrorSeverity.WARNING, "New expression does not resolve to a constructor"),
  NO_SUCH_TYPE("no such type \"%s\""),
  NO_SUCH_TYPE_CONSTRUCTOR("no such type \"%s\" in constructor"),
  NOT_A_CLASS("\"%s\" is not a class"),
  NOT_A_CLASS_OR_INTERFACE("\"%s\" is not a class or interface"),
  // TODO(zundel): error message needs JUnit test (reachable code?)
  NOT_A_LABEL("\"%s\" is not a label"),
  NOT_A_STATIC_FIELD("\"%s\" is not a static field"),
  NOT_A_STATIC_METHOD("\"%s\" is not a static method"),
  NOT_A_TYPE("type \"%s\" expected, but \"%s\" found"),
  // TODO(zundel): error message needs JUnit test (reachable code?)
  NOT_AN_INSTANCE_FIELD("%s is not an instance field"),
  REDIRECTED_CONSTRUCTOR_CYCLE("Redirected constructor call has a cycle."),
  PARAMETER_INIT_OUTSIDE_CONSTRUCTOR("Parameter initializers can only be used in constructors"),
  SUPER_METHOD_INVOCATION_IN_CONSTRUCTOR_INITIALIZER(
      "Super method invocation is not allowed in constructor initializer"),
  PARAMETER_INIT_STATIC_FIELD(
      "Parameter initializer cannot be use to initialize a static field '%s'"),
  // TODO(zundel): error message needs JUnit test (reachable code?)
  PARAMETER_INIT_WITH_REDIR_CONSTRUCTOR(
      "Parameter initializers cannot be used with redirected constructors"),
  // TODO(zundel): error message needs JUnit test
  PARAMETER_NOT_MATCH_FIELD("Could not match parameter initializer '%s' with any field"),
  RETHROW_NOT_IN_CATCH("Re-throw not in a catch block"),
  STATIC_FINAL_REQUIRES_VALUE("Static final fields must have an initial value"),
  SUPER_IN_FACTORY_CONSTRUCTOR("Cannot use 'super' in a factory constructor"),
  SUPER_IN_STATIC_METHOD("Cannot use 'super' in a static method"),
  SUPER_OUTSIDE_OF_METHOD("Cannot use 'super' outside of a method"),
  SUPER_ON_TOP_LEVEL("Cannot use 'super' in a top-level element"),
  THIS_IN_STATIC_METHOD("Cannot use 'this' in a static method"),
  THIS_IN_INITIALIZER_AS_EXPRESSION("Cannot reference 'this' as expression in initializer list"),
  THIS_ON_TOP_LEVEL("Cannot use 'this' in a top-level element"),
  THIS_OUTSIDE_OF_METHOD("Cannot use 'this' outside of a method"),
  THIS_IN_FACTORY_CONSTRUCTOR("Cannot use 'this' in a factory constructor"),
  TOO_FEW_ARGUMENTS_IN_IMPLICIT_SUPER("Too few arguments in implicit super() constructor invocation in '%s'"),
  TOO_MANY_QUALIFIERS_FOR_METHOD("Too many qualifiers for method or constructor"),
  TOPLEVEL_FINAL_REQUIRES_VALUE("Top-level final fields must have an initial value"),
  TYPE_VARIABLE_DOES_NOT_MATCH("Type variable %s does not match %s in default class %s."),
  TYPE_PARAMETERS_MUST_MATCH_EXACTLY(
      "Type parameters in default declaration must match referenced class exactly"),
  TYPE_VARIABLE_IN_STATIC_CONTEXT("cannot access type variable %s in static context"),
  TYPE_VARIABLE_NOT_ALLOWED_IN_IDENTIFIER(
      "type variables are not allowed in identifier expressions"),
  USING_LOCAL_VARIABLE_BEFORE_DECLARATION("Using local variable '%s' before its declaration in lexical scope"),
  WRONG_NUMBER_OF_TYPE_ARGUMENTS("%s: wrong number of type arguments (%d).  Expected %d");

  private final ErrorSeverity severity;
  private final String message;

  /**
   * Initialize a newly created error code to have the given message and ERROR severity.
   */
  private ResolverErrorCode(String message) {
    this(ErrorSeverity.ERROR, message);
  }

  /**
   * Initialize a newly created error code to have the given severity and message.
   */
  private ResolverErrorCode(ErrorSeverity severity, String message) {
    this.severity = severity;
    this.message = message;
  }

  @Override
  public String getMessage() {
    return message;
  }

  @Override
  public ErrorSeverity getErrorSeverity() {
    return severity;
  }

  @Override
  public SubSystem getSubSystem() {
    return SubSystem.RESOLVER;
  }

  @Override
  public boolean needsRecompilation() {
    return true;
  }
}