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

  public static void formatExpectations(StringBuffer out, List<DartCompilationError> errors,
                                        ErrorExpectation[] expectedErrors) {
    out.append(String.format("Expected %d errors\n", expectedErrors.length));
    for (ErrorExpectation errEx : expectedErrors) {
      out.append(String.format("  %s (%d,%d/%d)\n", errEx.errorCode.toString(),
                               errEx.line, errEx.column, errEx.length));
    }
    out.append(String.format("Encountered %d errors\n", errors.size()));
    for (DartCompilationError error : errors) {
      out.append(String.format("  %s (%d,%d/%d): %s\n", error.getErrorCode().toString(),
                               error.getLineNumber(), error.getColumnNumber(),
                               error.getLength(), error.getMessage()));
    }
  }
  /**
   * Asserts that given list of {@link DartCompilationError} is exactly same as expected.
   */
  public static void assertErrors(List<DartCompilationError> errors,
                                  ErrorExpectation... expectedErrors) {
    StringBuffer errorMessage = new StringBuffer();
    // count of errors
    if (errors.size() != expectedErrors.length) {
      errorMessage.append(String.format("Wrong number of errors encountered\n",
                                        expectedErrors.length,
                                        errors.size()));

      formatExpectations(errorMessage, errors, expectedErrors);
    } else {
      // content of errors
      for (int i = 0; i < expectedErrors.length; i++) {
        ErrorExpectation expectedError = expectedErrors[i];
        DartCompilationError actualError = errors.get(i);
        if (actualError.getErrorCode() != expectedError.errorCode
            || actualError.getLineNumber() != expectedError.line
            || actualError.getColumnNumber() != expectedError.column
            || actualError.getLength() != expectedError.length) {
          errorMessage.append(String.format("Expected errors didn't match actual\n"));
          formatExpectations(errorMessage, errors, expectedErrors);
          break;
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
