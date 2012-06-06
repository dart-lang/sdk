// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler.resolver;

import com.google.dart.compiler.ErrorCode;
import com.google.dart.compiler.ErrorSeverity;
import com.google.dart.compiler.SubSystem;

/**
 * {@link ErrorCode}s for type resolver.
 */
public enum TypeErrorCode implements ErrorCode {
  ABSTRACT_CLASS_WITHOUT_ABSTRACT_MODIFIER(
      "%s is an abstract class because it does not implement the inherited abstract members: %s"),
  ASSERT_BOOL("assert requires  'bool' expression or '() -> bool' function"),
  ASSERT_NUMBER_ARGUMENTS(ErrorSeverity.ERROR, "assert requires exactly one argument"),
  ASSERT_IS_STATEMENT(ErrorSeverity.ERROR, "assert is a statement, it cannot be used as an expression"),
  CANNOT_BE_RESOLVED("cannot resolve %s", true),
  CANNOT_OVERRIDE_TYPED_MEMBER("cannot override %s of %s because %s is not assignable to %s"),
  CANNOT_OVERRIDE_METHOD_DEFAULT_VALUE("cannot override method '%s', default value doesn't match '%s'"),
  CANNOT_OVERRIDE_METHOD_NOT_SUBTYPE("cannot override %s of %s because %s is not a subtype of %s"),
  CYCLIC_REFERENCE_TO_TYPE_VARIABLE(
      "Invalid type expression, cyclic reference to type variable '%s'"),
  DEFAULT_CONSTRUCTOR_TYPES(
      "Constructor '%s' in '%s' has parameters types (%s), doesn't match '%s' in '%s' with (%s)"),
  DUPLICATE_NAMED_ARGUMENT("Named parameter argument already provided as positional argument"),
  EXTRA_ARGUMENT("extra argument"),
  FIELD_HAS_NO_GETTER("Field '%s' has no getter"),
  FIELD_HAS_NO_SETTER("Field '%s' has no setter"),
  FIELD_IS_FINAL("Field '%s' is final"),
  FOR_IN_WITH_ITERATOR_FIELD("iterator is a field, expected an iterator() method"),
  FOR_IN_WITH_INVALID_ITERATOR_RETURN_TYPE("iterator method's return type is not assignable to %s"),
  INSTANTIATION_OF_ABSTRACT_CLASS("instantiation of an abstract class '%s'"),
  INSTANTIATION_OF_CLASS_WITH_UNIMPLEMENTED_MEMBERS(
      "instantiation of class %s with the inherited abstract members: %s"),
  INTERFACE_HAS_NO_METHOD_NAMED("%s has no method named \"%s\""),
  INTERNAL_ERROR("internal error: %s", true),
  IS_STATIC_FIELD_IN("\"%s\" is a static field in \"%s\""),
  IS_STATIC_METHOD_IN("\"%s\" is a static method in \"%s\""),
  MAP_LITERAL_KEY_UNIQUE("Map literal keys should be unique."),
  MEMBER_IS_A_CONSTRUCTOR("%s is a constructor in %s"),
  MISSING_ARGUMENT("missing argument of type %s"),
  MISSING_RETURN_VALUE("no return value; expected a value of type %s"),
  NO_SUCH_NAMED_PARAMETER("no such named parameter \"%s\" defined"),
  NO_SUCH_TYPE("no such type \"%s\"", true),
  NOT_A_FUNCTION("\"%s\" is not a function"),
  NOT_A_MEMBER_OF("\"%s\" is not a member of %s"),
  NOT_A_METHOD_IN("\"%s\" is not a method in %s"),
  OPERATOR_NEGATE_NUM_RETURN_TYPE("operator 'negate' should return numeric type"),
  OPERATOR_WRONG_OPERAND_TYPE("operand of \"%s\" must be assignable to \"%s\""),
  OVERRIDING_INHERITED_STATIC_MEMBER("overriding inherited static member %s of %s"),
  PLUS_CANNOT_BE_USED_FOR_STRING_CONCAT("'+' operator cannot be used for string concatentation"),
  SETTER_RETURN_TYPE("Specified return type of setter '%s' is non-void"),
  SETTER_TYPE_MUST_BE_ASSIGNABLE("Setter type '%s' must be assignable to getter type '%s'"),
  STATIC_MEMBER_ACCESSED_THROUGH_INSTANCE(
      "static member %s of %s cannot be accessed through an instance"),
  SUPERTYPE_HAS_FIELD("%s is a field in %s"),
  SUPERTYPE_HAS_METHOD("%s is a method in %s"),
  TYPE_VARIABLE_IN_STATIC_CONTEXT("cannot access type variable %s in static context"),
  TYPE_NOT_ASSIGNMENT_COMPATIBLE("'%s' is not assignable to '%s'"),
  USE_ASSIGNMENT_ON_SETTER("Use assignment to set field \"%s\" in %s"),
  VOID("expression does not yield a value"),
  WRONG_NUMBER_OF_TYPE_ARGUMENTS("%s: wrong number of type arguments (%d), Expected %d");

  private final ErrorSeverity severity;
  private final String message;
  private final boolean needsRecompilation;

  /**
   * Initialize a newly created error code to have the given message.
   */
  private TypeErrorCode(String message) {
    this(message, false);
  }

  /**
   * Initialize a newly created error code to have the given message and compilation flag.
   */
  private TypeErrorCode(String message, boolean needsRecompilation) {
    this(ErrorSeverity.WARNING, message);
  }

  private TypeErrorCode(ErrorSeverity severity, String message) {
    this(severity, message, false);
  }
  
  private TypeErrorCode(ErrorSeverity severity, String message, boolean needsRecompilation) {
    this.severity = severity;
    this.message = message;
    this.needsRecompilation = needsRecompilation;
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
    return SubSystem.STATIC_TYPE;
  }

  @Override
  public boolean needsRecompilation() {
    return this.needsRecompilation;
  }
}