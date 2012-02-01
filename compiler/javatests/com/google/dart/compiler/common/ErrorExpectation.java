// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler.common;

import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.ErrorCode;

import junit.framework.Assert;

import java.util.List;

public class ErrorExpectation {
  private final String sourceName;
  final ErrorCode errorCode;
  final int line;
  final int column;
  final int length;

  public ErrorExpectation(String sourceName, ErrorCode errorCode, int line, int column, int length) {
    this.sourceName = sourceName;
    this.errorCode = errorCode;
    this.line = line;
    this.column = column;
    this.length = length;
  }

  public static ErrorExpectation errEx(String sourceName,
      ErrorCode errorCode,
      int line,
      int column,
      int length) {
    sourceName = sourceName != null ? sourceName : "";
    return new ErrorExpectation(sourceName, errorCode, line, column, length);
  }

  public static ErrorExpectation errEx(ErrorCode errorCode, int line, int column, int length) {
    return new ErrorExpectation("", errorCode, line, column, length);
  }

  public static void formatExpectations(StringBuffer out,
      List<DartCompilationError> errors,
      ErrorExpectation[] expectedErrors) {
    out.append(String.format("Expected %d errors\n", expectedErrors.length));
    boolean hasExpectedSourceName = false;
    for (ErrorExpectation expected : expectedErrors) {
      hasExpectedSourceName |= expected.sourceName.length() != 0;
      out.append(String.format(
          "  %s %s (%d,%d/%d)\n",
          expected.sourceName,
          expected.errorCode.toString(),
          expected.line,
          expected.column,
          expected.length));
    }
    out.append(String.format("Encountered %d errors\n", errors.size()));
    for (DartCompilationError actual : errors) {
      String sourceName =
          hasExpectedSourceName && actual.getSource() != null ? actual.getSource().getName() : "";
      out.append(String.format(
          "  %s %s (%d,%d/%d): %s\n",
          sourceName,
          actual.getErrorCode().toString(),
          actual.getLineNumber(),
          actual.getColumnNumber(),
          actual.getLength(),
          actual.getMessage()));
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
      errorMessage.append(String.format(
          "Wrong number of errors encountered\n",
          expectedErrors.length,
          errors.size()));
      formatExpectations(errorMessage, errors, expectedErrors);
    } else {
      // content of errors
      for (int i = 0; i < expectedErrors.length; i++) {
        ErrorExpectation expected = expectedErrors[i];
        DartCompilationError actual = errors.get(i);
        String expectedSourceName = expected.sourceName;
        String actualSourceName = actual.getSource() != null ? actual.getSource().getName() : "";
        if (actual.getErrorCode() != expected.errorCode
            || actual.getLineNumber() != expected.line
            || actual.getColumnNumber() != expected.column
            || actual.getLength() != expected.length
            || !(expectedSourceName.length() == 0 || expectedSourceName.equals(actualSourceName))) {
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
