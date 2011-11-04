// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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
  ABSTRACT_CLASS("%s is an abstract class because it does not implement the following members:%s"),
  CANNOT_BE_RESOLVED("cannot resolve %s"),
  CANNOT_INSTATIATE_ABSTRACT_CLASS("cannot instantiate abstract class %s"),
  CANNOT_OVERRIDE_TYPED_MEMBER("cannot override %s of %s because %s is not assignable to %s"),
  CANNOT_OVERRIDE_METHOD_NOT_SUBTYPE("cannot override %s of %s because %s is not a subtype of %s"),
  EXTRA_ARGUMENT("extra argument"),
  FOR_IN_WITH_ITERATOR_FIELD("iterator is a field, expected an iterator() method"),
  FOR_IN_WITH_INVALID_ITERATOR_RETURN_TYPE("iterator method's return type is not assignable to %s"),
  INTERFACE_HAS_NO_METHOD_NAMED("%s has no method named \"%s\""),
  INTERNAL_ERROR("internal error: %s"),
  IS_STATIC_FIELD_IN("\"%s\" is a static field in \"%s\""),
  IS_STATIC_METHOD_IN("\"%s\" is a static method in \"%s\""),
  MEMBER_IS_A_CONSTRUCTOR("%s is a constructor in %s"),
  MISSING_ARGUMENT("missing argument of type %s"),
  MISSING_RETURN_VALUE("no return value; expected a value of type %s"),
  NO_SUCH_TYPE("no such type \"%s\""),
  NOT_A_FUNCTION("\"%s\" is not a function"),
  NOT_A_MEMBER_OF("\"%s\" is not a member of %s"),
  NOT_A_METHOD_IN("\"%s\" is not a method in %s"),
  NOT_A_TYPE("type \"%s\" expected, but \"%s\" found"),
  OPERATOR_WRONG_OPERAND_TYPE("operand of \"%s\" must be assignable to \"%s\""),
  STATIC_MEMBER_ACCESSED_THROUGH_INSTANCE(
      "static member %s of %s cannot be accessed through an instance"),
  SUPERTYPE_HAS_FIELD("%s is a field in %s"),
  SUPERTYPE_HAS_METHOD("%s is a method in %s"),
  TYPE_NOT_ASSIGNMENT_COMPATIBLE("%s is not assignable to %s"),
  VOID("expression does not yield a value"),
  WRONG_NUMBER_OF_TYPE_ARGUMENTS("%s: wrong number of type arguments");
  private final ErrorSeverity severity;
  private final String message;

  /**
   * Initialize a newly created error code to have the given message and WARNING severity.
   */
  private TypeErrorCode(String message) {
    this(ErrorSeverity.WARNING, message);
  }

  /**
   * Initialize a newly created error code to have the given severity and message.
   */
  private TypeErrorCode(ErrorSeverity severity, String message) {
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
    return SubSystem.STATIC_TYPE;
  }
}