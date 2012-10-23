// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

/**
 * Valid error codes for the errors produced by the Dart compiler.
 */
public enum DartCompilerErrorCode implements ErrorCode {
  CONSOLE_WEB_MIX(ErrorSeverity.INFO,
      "Libraries 'dart:io' (console apps only) and 'dart:html' (web apps only) cannot be used together"),
  ENTRY_POINT_METHOD_CANNOT_HAVE_PARAMETERS(ErrorSeverity.WARNING, 
      "Main entry point method cannot have parameters"),
  ENTRY_POINT_METHOD_MAY_NOT_BE_GETTER(ErrorSeverity.WARNING,
      "Entry point \"%s\" may not be a getter"),
  ENTRY_POINT_METHOD_MAY_NOT_BE_SETTER(ErrorSeverity.WARNING,
      "Entry point \"%s\" may not be a setter"),
  ILLEGAL_DIRECTIVES_IN_SOURCED_UNIT("This part was included by %s via a "
      + "part directive, so cannot itself contain directives other than a part of directive"),
  IO("Input/Output error: %s"),
  MIRRORS_NOT_FULLY_IMPLEMENTED(ErrorSeverity.WARNING, "dart:mirrors is not fully implemented yet"),
  MISSING_LIBRARY_DIRECTIVE("a library which is imported is missing a library directive: %s"),
  MISSING_SOURCE("Cannot find referenced source: %s"),
  UNIT_WAS_ALREADY_INCLUDED("Unit '%s' was already included");
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
