// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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
  CANNOT_INIT_STATIC_FIELD_IN_INITIALIZER("Cannot initialize a static field in an initializer list"),
  CANNOT_OVERRIDE_INSTANCE_MEMBER("static member cannot override instance member %s of %s"),
  CANNOT_OVERRIDE_STATIC_MEMBER("cannot override static member %s of %s"),
  CANNOT_RESOLVE_CONSTRUCTOR("cannot resolve constructor %s"),
  CANNOT_RESOLVE_FIELD("cannot resolve field %s"),
  CANNOT_RESOLVE_LABEL("cannot resolve label %s"),
  CANNOT_RESOLVE_METHOD("cannot resolve method %s"),
  CANNOT_RESOLVE_SUPER_CONSTRUCTOR("cannot resolve method %s"),
  CANNOT_RESOLVE_IMPLICIT_CALL_TO_SUPER_CONSTRUCTOR(
      "super type %s does not have a default constructor"),
  CIRCULAR_REFERENCE(
      "Circular reference detected:  compile-time constants cannot reference themselves."),
  CONSTRUCTOR_CANNOT_BE_ABSTRACT("A constructor cannot be asbstract"),
  CONSTRUCTOR_CANNOT_BE_STATIC("A constructor cannot be static"),
  CONSTRUCTOR_CANNOT_HAVE_RETURN_TYPE("Generative constructors cannot have return type"),
  CONST_AND_NONCONST_CONSTRUCTOR("cont reference to non-const constructor."),
  CONST_CONSTRUCTOR_CANNOT_HAVE_BODY("A const constructor cannot have a body"),
  CONST_CONSTRUCTOR_MUST_CALL_CONST_SUPER("const constructor must call const super constructor"),
  CONSTANTS_MUST_BE_INITIALIZED("constants must be initialized"),
  CYCLIC_CLASS("%s causes a cycle in the supertype graph"),
  DID_YOU_MEAN_NEW("%1$s is a %2$s. Did you mean (new %1$s)?"),
  DUPLICATE_DEFINITION("duplicate definition of %s"),
  DUPLICATED_INTERFACE("%s and %s are duplicated in the supertype graph"),
  DYNAMIC_EXTENDS("Dynamic can not be used as superclass"),
  DYNAMIC_IMPLEMENTS("Dynamic can not be used as superinterface"),
  EXPECTED_AN_INSTANCE_FIELD_IN_SUPER_CLASS(
      "expected an instance field in the super class, but got %s"),
  EXPECTED_CONSTANT_EXPRESSION("Expected constant expression"),
  EXPECTED_CONSTANT_EXPRESSION_BOOLEAN("Expected constant expression of type bool, got %s"),
  EXPECTED_CONSTANT_EXPRESSION_INT("Expected constant expression of type int, got %s"),
  EXPECTED_CONSTANT_EXPRESSION_NUMBER("Expected constant expression of type num, got %s"),
  EXPECTED_CONSTANT_EXPRESSION_STRING_NUMBER_BOOL(
      "Expected constant expression of type String, num or bool, got %s"),
  EXPECTED_FIELD_NOT_CLASS("%s is a class, expected a local field"),
  EXPECTED_FIELD_NOT_METHOD("%s is a method, expected a local field"),
  EXPECTED_FIELD_NOT_PARAMETER("%s is a parameter, expected a local field"),
  EXPECTED_FIELD_NOT_TYPE_VAR("%s is a type variable, expected a local field"),
  EXPECTED_ONE_ARGUMENT("Expected one argument"),
  EXPECTED_STATIC_FIELD("expected a static field, but got %s"),
  EXTRA_TYPE_ARGUMENT("Type variables may not have type arguments"),
  FACTORY_ACCESS_SUPER("Cannot use 'super' in a factory constructor"),
  FACTORY_CANNOT_BE_ABSTRACT("A factory cannot be abstract"),
  FACTORY_CANNOT_BE_CONST("A factory cannot be const"),
  FACTORY_CANNOT_BE_STATIC("A factory cannot be static"),
  FACTORY_CONSTRUCTOR_SIGNATURE_DOES_NOT_MATCH("Factory constructor signature does not match"),
  FACTORY_CONSTRUCTOR_TYPE_ARGS_DO_NOT_MATCH("Factory constructor type arguments do not match"),
  FIELD_CONFLICTS("%s conflicts with previously defined %s at line %d column %d"),
  ILLEGAL_ACCESS_TO_PRIVATE_MEMBER("\"%s\" refers to \"%s\" which is in a different library"),
  ILLEGAL_FIELD_ACCESS_FROM_STATIC("Illegal access of instance field %s from static scope"),
  ILLEGAL_METHOD_ACCESS_FROM_STATIC("Illegal access of instance method %s from static scope"),
  INSTANCE_METHOD_FROM_STATIC("Instance methods cannot be referenced from static methods"),
  INTERNAL_ERROR("internal error: %s"),
  INVALID_RETURN_IN_CONSTRUCTOR("Generative constructors cannot return arbitrary expressions"),
  INVALID_TYPE_NAME_IN_CONSTRUCTOR("Invalid type in constructor name"),
  IS_A_CLASS("%s is a class and cannot be used as an expression"),
  IS_A_CONSTRUCTOR("%s.%s is a constructor, expected a  method"),
  IS_AN_INSTANCE_METHOD("%s.%s is an instance method, not a static method"),
  METHOD_MUST_HAVE_BODY("A non-abstract method must have a body"),
  NAME_CLASHES_EXISTING_MEMBER(
      "name clashes with a previously defined member at %sline %d column %d"),
  NEW_EXPRESSION_CANT_USE_TYPE_VAR("New expression cannot be invoked on type variable"),
  NEW_EXPRESSION_FACTORY_CONSTRUCTOR("Can not resolve constructor with name '%s' in factory '%s'"),
  NEW_EXPRESSION_NOT_CONSTRUCTOR("New expression does not resolve to a constructor"),
  NO_SUCH_TYPE("no such type \"%s\""),
  NO_SUCH_TYPE_CONSTRUCTOR("no such type \"%s\" in constructor"),
  NOT_A_CLASS("\"%s\" is not a class"),
  NOT_A_CLASS_OR_INTERFACE("\"%s\" is not a class or interface"),
  NOT_A_LABEL("\"%s\" is not a label"),
  NOT_A_STATIC_FIELD("\"%s\" is not a static field"),
  NOT_A_STATIC_METHOD("\"%s\" is not a static method"),
  NOT_AN_INSTANCE_FIELD("%s is not an instance field"),
  REDIRECTED_CONSTRUCTOR_CYCLE("Redirected constructor call has a cycle."),
  PARAMETER_INIT_OUTSIDE_CONSTRUCTOR("Parameter initializers can only be used in constructors"),
  PARAMETER_INIT_STATIC_FIELD(
      "Parameter initializer cannot be use to initialize a static field '%s'"),
  PARAMETER_INIT_WITH_REDIR_CONSTRUCTOR(
      "Parameter initializers cannot be used with redirected constructors"),
  PARAMETER_NOT_MATCH_FIELD("Could not match parameter initializer '%s' with any field"),
  RETHROW_NOT_IN_CATCH("Re-throw not in a catch block"),
  STATIC_FINAL_REQUIRES_VALUE("Static final fields must have an initial value"),
  STATIC_METHOD_ACCESS_SUPER("Cannot use 'super' in a static method"),
  STATIC_METHOD_ACCESS_THIS("Cannot use 'this' in a static method"),
  SUPER_OUTSIDE_OF_METHOD("Cannot use 'super' outside of a method"),
  TOO_MANY_QUALIFIERS_FOR_METHOD("Too many qualifiers for method or constructor"),
  TOP_LEVEL_METHOD_ACCESS_SUPER("Cannot use 'super' in a top-level method"),
  TOP_LEVEL_METHOD_ACCESS_THIS("Cannot use 'this' in a top-level method"),
  TYPE_ARGS_ONLY_ON_CONSTRUCTORS("Type arguments are only allowed on constructor methods"),
  TYPE_NOT_ASSIGNMENT_COMPATIBLE("%s is not assignable to %s"),
  TYPE_VARIABLE_IN_STATIC_CONTEXT("cannot access type variable %s in static context"),
  WRONG_NUMBER_OF_TYPE_ARGUMENTS("%s: wrong number of type arguments");
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
}