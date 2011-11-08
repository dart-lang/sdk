// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.dart.compiler.ast.DartUnit;

import java.io.PrintStream;

/**
 * A default implementation of {@link DartCompilerListener} which counts
 * compilation errors.
 */
public class DefaultDartCompilerListener extends DartCompilerListener {

  /**
   * The number of (fatal) problems that occurred during compilation.
   */
  private int errorCount = 0;

  /**
   * The number of (non-fatal) problems that occurred during compilation.
   */
  private int warningCount = 0;

  /**
   * The number of (non-fatal) problems that occurred during compilation.
   */
  private int typeErrorCount = 0;

  /**
   * Formatter used to report error messages. Marked protected so that
   * subclasses can override it (e.g. for a test server using HTML formatting).
   */
  protected final ErrorFormatter formatter;

  public DefaultDartCompilerListener(boolean printMachineProblems) {
    this(System.err, printMachineProblems);
  }

  /**
   * @param outputStream the {@link PrintStream} to use for {@link ErrorFormatter}.
   */
  public DefaultDartCompilerListener(PrintStream outputStream, boolean printMachineProblems) {
    formatter = new  PrettyErrorFormatter(outputStream, useColor(), printMachineProblems);
  }

  @Override
  public void onError(DartCompilationError event) {
    formatter.format(event);
    if (event.getErrorCode().getSubSystem() == SubSystem.STATIC_TYPE) {
      incrementTypeErrorCount();
    } else if (event.getErrorCode().getErrorSeverity() == ErrorSeverity.ERROR) {
      incrementErrorCount();
    } else if (event.getErrorCode().getErrorSeverity() == ErrorSeverity.WARNING) {
      incrementWarningCount();
    }
  }

  private boolean useColor() {
    return String.valueOf(System.getenv("TERM")).startsWith("xterm") && System.console() != null;
  }

  /**
   * Answer the number of fatal errors that occurred during compilation.
   *
   * @return the number of problems
   */
  public int getErrorCount() {
    return errorCount;
  }

  /**
   * Answer the number of non-fatal warnings that occurred during compilation.
   *
   * @return the number of problems
   */
  public int getWarningCount() {
    return warningCount;
  }

  /**
   * Answer the number of non-fatal type problems that occurred during compilation.
   *
   * @return the number of problems
   */
  public int getTypeErrorCount() {
    return typeErrorCount;
  }

  /**
   * Increment the {@link #errorCount} by 1
   */
  protected void incrementErrorCount() {
    errorCount++;
  }

  /**
   * Increment the {@link #warningCount} by 1
   */
  protected void incrementWarningCount() {
    warningCount++;
  }

  /**
   * Increment the {@link #typeErrorCount} by 1
   */
  protected void incrementTypeErrorCount() {
    typeErrorCount++;
  }

  @Override
  public void unitCompiled(DartUnit unit) {
  }
}
