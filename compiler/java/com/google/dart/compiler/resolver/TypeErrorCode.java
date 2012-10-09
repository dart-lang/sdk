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
  ASSERT_BOOL("assert requires  'bool' expression or '() -> bool' function"),
  CANNOT_ASSIGN_TO("cannot assign to '%s'"),
  CANNOT_BE_RESOLVED("cannot resolve %s", true),
  CANNOT_OVERRIDE_TYPED_MEMBER("cannot override %s of %s because %s is not assignable to %s"),
  CANNOT_OVERRIDE_METHOD_DEFAULT_VALUE("cannot override method '%s', default value doesn't match '%s'"),
  CANNOT_OVERRIDE_METHOD_NOT_SUBTYPE("cannot override %s of %s because %s is not a subtype of %s"),
  CONTRETE_CLASS_WITH_UNIMPLEMENTED_MEMBERS("Concrete class %s has unimplemented member(s) %s"),
  CYCLIC_REFERENCE_TO_TYPE_VARIABLE(
      "Invalid type expression, cyclic reference to type variable '%s'"),
  DEPRECATED_ELEMENT(ErrorSeverity.INFO, "%s is deprecated"),
  DEFAULT_CONSTRUCTOR_TYPES(
      "Constructor '%s' in '%s' has parameters types (%s), doesn't match '%s' in '%s' with (%s)"),
  DUPLICATE_NAMED_ARGUMENT("Named parameter argument already provided as positional argument"),
  CASE_EXPRESSION_TYPE_SHOULD_NOT_HAVE_EQUALS(ErrorSeverity.ERROR,
      "Case expression type '%s' should not implement operator =="),
  CASE_EXPRESSIONS_SHOULD_BE_SAME_TYPE(ErrorSeverity.ERROR,
      "All case expressions should be compiler-time constants of the same type - 'int' or 'String'. '%s' expected but '%s' found"),
  EXPECTED_POSITIONAL_ARGUMENT("Expected positional argument of type %s before named arguments"),
  EXTRA_ARGUMENT("extra argument"),
  FIELD_HAS_NO_GETTER("Field '%s' has no getter"),
  FIELD_HAS_NO_SETTER("Field '%s' has no setter"),
  FIELD_IS_FINAL("Field '%s' is final"),
  FOR_IN_WITH_ITERATOR_FIELD("iterator is a field, expected an iterator() method"),
  FOR_IN_WITH_INVALID_ITERATOR_RETURN_TYPE("iterator method's return type is not assignable to %s"),
  ILLEGAL_ACCESS_TO_PRIVATE("'%s' is private and not defined in this library"),
  INCOMPATIBLE_TYPES_IN_HIERARCHY(ErrorSeverity.INFO,
      "Class inherits two variations of the same interface '%s' and '%s' with parameters that are not assignable to each other."),
  INSTANTIATION_OF_ABSTRACT_CLASS("instantiation of an abstract class '%s'"),
  INTERFACE_HAS_NO_METHOD_NAMED("\"%s\" has no method named \"%s\""),
  INTERFACE_HAS_NO_METHOD_NAMED_INFERRED(ErrorSeverity.INFO, "\"%s\" has no method named \"%s\""),
  INTERNAL_ERROR("internal error: %s", true),
  IS_STATIC_FIELD_IN("\"%s\" is a static field in \"%s\""),
  IS_STATIC_METHOD_IN("\"%s\" is a static method in \"%s\""),
  MAP_LITERAL_KEY_UNIQUE("Map literal keys should be unique."),
  MEMBER_IS_A_CONSTRUCTOR("%s is a constructor in %s"),
  MISSING_ARGUMENT("missing argument of type %s"),
  MISSING_RETURN_VALUE("no return value; expected a value of type %s"),
  NO_SUCH_NAMED_PARAMETER("no such named parameter \"%s\" defined"),
  NO_SUCH_TYPE("no such type \"%s\"", true),
  NOT_A_FUNCTION_TYPE("\"%s\" is not a function type"),
  NOT_A_MEMBER_OF("\"%s\" is not a member of %s"),
  NOT_A_MEMBER_OF_INFERRED(ErrorSeverity.INFO, "\"%s\" is not a member of %s"),
  NOT_A_METHOD_IN("\"%s\" is not a method in %s"),
  NOT_A_METHOD_IN_INFERRED(ErrorSeverity.INFO, "\"%s\" is not a method in %s"),
  NOT_A_TYPE("type \"%s\" expected, but \"%s\" found"),
  OPERATOR_EQUALS_BOOL_RETURN_TYPE("operator 'equals' should return bool type"),
  OPERATOR_INDEX_ASSIGN_VOID_RETURN_TYPE("operator '[]=' must have a return type of 'void'"),
  OPERATOR_WRONG_OPERAND_TYPE("operand of \"%s\" must be assignable to \"%s\", found \"%s\""),
  OVERRIDING_STATIC_MEMBER("overriding static member \"%s\" of \"%s\""),
  PLUS_CANNOT_BE_USED_FOR_STRING_CONCAT("'%s' cannot be used for string concatentation, use string interpolation or a StringBuffer instead"),
  SETTER_RETURN_TYPE("Specified return type of setter '%s' is non-void"),
  SETTER_TYPE_MUST_BE_ASSIGNABLE("Setter type '%s' must be assignable to getter type '%s'"),
  STATIC_MEMBER_ACCESSED_THROUGH_INSTANCE(
      "static member %s of %s cannot be accessed through an instance"),
  SUPERTYPE_HAS_FIELD(ErrorSeverity.ERROR, "%s is a field in %s"),
  SUPERTYPE_HAS_METHOD(ErrorSeverity.ERROR, "%s is a method in %s"),
  TYPE_ALIAS_CANNOT_REFERENCE_ITSELF(ErrorSeverity.ERROR,
      "Type alias cannot reference itself directly of via other typedefs"),
  TYPE_NOT_ASSIGNMENT_COMPATIBLE("'%s' is not assignable to '%s'"),
  TYPE_NOT_ASSIGNMENT_COMPATIBLE_INFERRED(ErrorSeverity.INFO, "'%s' is not assignable to '%s'"),
  USE_ASSIGNMENT_ON_SETTER("Use assignment to set field '%s'"),
  USE_INTEGER_DIVISION("Use integer division ~/ instead"),
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
    this(ErrorSeverity.WARNING, message, needsRecompilation);
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