// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.common;

import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.ErrorCode;

import junit.framework.Assert;

import java.util.List;

public class ErrorExpectation {
  final ErrorCode errorCode;
  final int line;
  final int column;
  final int length;

  public ErrorExpectation(ErrorCode errorCode, int line, int column, int length) {
    this.errorCode = errorCode;
    this.line = line;
    this.column = column;
    this.length = length;
  }

  public static ErrorExpectation errEx(ErrorCode errorCode, int line, int column, int length) {
    return new ErrorExpectation(errorCode, line, column,  length);
  }

  /**
   * Asserts that given list of {@link DartCompilationError} is exactly same as expected.
   */
  public static void assertErrors(List<DartCompilationError> errors,
      ErrorExpectation... expectedErrors) {
    StringBuffer errorMessage = new StringBuffer();
    // count of errors
    if (errors.size() != expectedErrors.length) {
      String out =
          String.format(
              "Expected %s errors, but got %s: %s",
              expectedErrors.length,
              errors.size(),
              errors);
      errorMessage.append(out + "\n");
    } else {
      // content of errors
      for (int i = 0; i < expectedErrors.length; i++) {
        ErrorExpectation expectedError = expectedErrors[i];
        DartCompilationError actualError = errors.get(i);
        if (actualError.getErrorCode() != expectedError.errorCode
            || actualError.getLineNumber() != expectedError.line
            || actualError.getColumnNumber() != expectedError.column
            || actualError.getLength() != expectedError.length) {
          String out =
              String.format(
                  "Expected %s:%d:%d/%d, but got %s:%d:%d/%d",
                  expectedError.errorCode,
                  expectedError.line,
                  expectedError.column,
                  expectedError.length,
                  actualError.getErrorCode(),
                  actualError.getLineNumber(),
                  actualError.getColumnNumber(),
                  actualError.getLength());
          errorMessage.append(out + "\n");
        }
      }
    }
    // fail
    if (errorMessage.length() > 0) {
      System.err.println(errorMessage);
      Assert.fail(errorMessage.toString());
    }
  }
}
