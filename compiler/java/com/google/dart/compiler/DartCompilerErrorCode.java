// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

/**
 * Valid error codes for the errors produced by the Dart compiler.
 */
public enum DartCompilerErrorCode implements ErrorCode {
  ENTRY_POINT_METHOD_CANNOT_HAVE_PARAMETERS(ErrorSeverity.WARNING, 
      "Main entry point method cannot have parameters"),
  ENTRY_POINT_METHOD_MAY_NOT_BE_GETTER(ErrorSeverity.WARNING,
      "Entry point \"%s\" may not be a getter"),
  ENTRY_POINT_METHOD_MAY_NOT_BE_SETTER(ErrorSeverity.WARNING,
      "Entry point \"%s\" may not be a setter"),
  ILLEGAL_DIRECTIVES_IN_SOURCED_UNIT("This source was included by %s via a "
      + "#source directive, so cannot itself contain directives"),
  IO("Input/Output error: %s"),
  MISSING_LIBRARY_DIRECTIVE("a library which is imported is missing a #library directive: %s"),
  MISSING_SOURCE("Cannot find referenced source: %s");
  private final ErrorSeverity severity;
  private final String message;

  /**
   * Initialize a newly created error code to have the given message and ERROR severity.
   */
  private DartCompilerErrorCode(String message) {
    this(ErrorSeverity.ERROR, message);
  }

  /**
   * Initialize a newly created error code to have the given severity and message.
   */
  private DartCompilerErrorCode(ErrorSeverity severity, String message) {
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
    return SubSystem.COMPILER;
  }

  @Override
  public boolean needsRecompilation() {
    return true;
  }
}
