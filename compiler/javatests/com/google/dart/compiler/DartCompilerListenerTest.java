// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.dart.compiler.ast.DartUnit;

/**
 * Testing implementation of {@link DartCompilerListener}.
 */
public class DartCompilerListenerTest extends DartCompilerListener {

  private final String srcName;
  private String[] messages;
  private ErrorCode[] errorCodes;
  private int[] line;
  private int[] column;
  private int total;
  private int current;

  /**
   * Creates a listener with expected errors (if any).
   *
   * @param srcName name of the source file
   * @param errors a sequence of errors represented as triples of the form
   *        (String msg, int line, int column) or
   *        (ErrorCode code, int line, int column)
   */
  public DartCompilerListenerTest(String srcName, Object... errors) {
    this.srcName = srcName;
    CompilerTestCase.assertEquals(
        "Invalid sequence of error expectations", 0, errors.length % 3);
    this.total = errors.length / 3;
    this.current = 0;
    this.messages = new String[total];
    this.errorCodes = new ErrorCode[total];
    this.line = new int[total];
    this.column = new int[total];
    for (int i = 0; i < total; i++) {
      Object stringOrErrorCode = errors[3 * i];
      if (stringOrErrorCode instanceof ErrorCode) {
        this.errorCodes[i] = (ErrorCode) stringOrErrorCode;
      } else {
        this.messages[i] = (String) stringOrErrorCode;
      }
      this.line[i] = (Integer) errors[(3 * i) + 1];
      this.column[i] = (Integer) errors[(3 * i) + 2];
    }
  }

  @Override
  public void compilationError(DartCompilationError event) {
    String reportedSrcName = (event.getSource() != null)
        ? event.getSource().getName()
        : null;
    if (reportedSrcName == null) {
      reportedSrcName = "<unknown>";
    }
    CompilerTestCase.assertTrue("More errors (" + (current + 1)
        + ") than expected (" + total + "):\n" + event,
        current < total);

    CompilerTestCase.assertEquals(srcName, reportedSrcName);

    if (errorCodes[current] != null) {
      CompilerTestCase.assertEquals(
        "Wrong error code", errorCodes[current], event.getErrorCode());
    } else {
      CompilerTestCase.assertEquals(
        "Wrong error message", messages[current], event.getMessage());
    }
    CompilerTestCase.assertEquals(
        "Wrong line number", line[current], event.getLineNumber());
    CompilerTestCase.assertEquals(
        "Wrong column number", column[current], event.getColumnNumber());
    current++;
  }

  @Override
  public void compilationWarning(DartCompilationError event) {
    compilationError(event);
  }

  @Override
  public void typeError(DartCompilationError event) {
    compilationError(event);
  }

  /** Checks that all expected errors were reported. */
  public void checkAllErrorsReported() {
    CompilerTestCase.assertEquals("Not all expected errors were reported",
        total, current);
  }

  @Override
  public void unitCompiled(DartUnit unit) {
  }
}
