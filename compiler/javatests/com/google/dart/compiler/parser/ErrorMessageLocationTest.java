// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import com.google.dart.compiler.DartCompilationError;

import junit.framework.TestCase;

import java.util.List;

/**
 * Test that error messages cover the correct locations in the source code.
 */
public class ErrorMessageLocationTest extends TestCase {
  /**
   * Test that unexpected token highlights the correct location in the file.
   */
  public void testUnexpectedTokenErrorMessage() {
    String sourceCode =
        "// Empty comment\n" +
        "class foo while Bar {\n" +
        "}";

    DartParserRunner runner = DartParserRunner.parse(getName(), sourceCode);
    List<DartCompilationError> actualErrors = runner.getErrors();

    // Due to error recovery more than a single error is generated
    DartCompilationError actualError = actualErrors.get(0);

    String errorTokenString = "while";
    assertEquals(11, actualError.getColumnNumber());
    assertEquals(errorTokenString.length(), actualError.getLength());
    assertEquals(2, actualError.getLineNumber());
    assertEquals(sourceCode.indexOf(errorTokenString), actualError.getStartPosition());
  }

  public void testExpectedLeftParenErrorMessage1() {
    String sourceCode =
        "// comment to change the line\n" +
        "main () {\n" +
        "  var x = new PART1.PART2.PART3.PART4();\n" +
        "}\n";

    DartParserRunner runner = DartParserRunner.parse(getName(), sourceCode);
    List<DartCompilationError> actualErrors = runner.getErrors();

    // Due to error recovery more than a single error is generated
    DartCompilationError actualError = actualErrors.get(0);

    String errorTokenString = "PART4";
    assertEquals(33, actualError.getColumnNumber());
    assertEquals(errorTokenString.length(), actualError.getLength());
    assertEquals(3, actualError.getLineNumber());
    assertEquals(sourceCode.indexOf(errorTokenString), actualError.getStartPosition());
  }
}
