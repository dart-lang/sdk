// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

/**
 * A default implementation of {@link DartCompilerListener} which counts
 * compilation errors.
 */
public class DefaultDartCompilerListener extends DartCompilerListener {

  /**
   * The number of (fatal) problems that occurred during compilation.
   */
  private int problemCount = 0;

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
  protected ErrorFormatter formatter = new PrettyErrorFormatter(useColor());

  @Override
  public void compilationError(DartCompilationError event) {
    formatter.format(event);
    incrementProblemCount();
  }

  @Override
  public void compilationWarning(DartCompilationError event) {
    formatter.format(event);
    incrementWarningCount();
  }

  @Override
  public void typeError(DartCompilationError event) {
    formatter.format(event);
    incrementTypeErrorCount();
  }

  private boolean useColor() {
    return String.valueOf(System.getenv("TERM")).startsWith("xterm");
  }

  /**
   * Answer the number of (fatal) problems that occurred during compilation.
   *
   * @return the number of problems
   */
  public int getProblemCount() {
    return problemCount;
  }

  /**
   * Answer the number of (non-fatal) problems that occurred during compilation.
   *
   * @return the number of problems
   */
  public int getWarningCount() {
    return warningCount;
  }

  /**
   * Answer the number of (non-fatal) problems that occurred during compilation.
   *
   * @return the number of problems
   */
  public int getTypeErrorCount() {
    return typeErrorCount;
  }

  /**
   * Increment the {@link #problemCount} by 1
   */
  protected void incrementProblemCount() {
    problemCount++;
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
}
