// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler;

/**
 * The behavior common to objects representing error codes associated with
 * {@link DartCompilationError Dart compilation errors}.
 */
public interface ErrorCode {
  /**
   * Return the message template used to create the message to be displayed for this error.
   */
  String getMessage();

  /**
   * @return the {@link ErrorSeverity} of this error.
   */
  ErrorSeverity getErrorSeverity();

  /**
   * @return the {@link SubSystem} which issued this error.
   */
  SubSystem getSubSystem();
}
