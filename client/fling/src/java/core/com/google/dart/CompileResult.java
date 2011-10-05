// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart;

import java.io.Serializable;
import java.util.List;

/**
 * Contains the full results of a invocation of
 * {@link CompileService#build(String, String)} or
 * {@link CompileService#build(java.io.File)}.
 */
@SuppressWarnings("serial")
public class CompileResult implements Serializable {
  private final String binary;
  private final List<CompileError> typeErrors;
  private final List<CompileError> fatalErrors;
  private final List<CompileError> warnings;
  private final Throwable exception;
  private final long duration;

  CompileResult(List<CompileError> fatalErrors, List<CompileError> typeErrors, List<CompileError> warnings,
      Throwable exception, long duration) {
    this.binary = null;
    this.fatalErrors = fatalErrors;
    this.typeErrors = typeErrors;
    this.warnings = warnings;
    this.exception = exception;
    this.duration = duration;
  }

  CompileResult(String binary, List<CompileError> fatalErrors, List<CompileError> typeErrors,
      List<CompileError> warnings, long duration) {
    this.binary = binary;
    this.typeErrors = typeErrors;
    this.fatalErrors = fatalErrors;
    this.warnings = warnings;
    this.exception = null;
    this.duration = duration;
  }

  /**
   * Indicates whether the build was successful. If false, {@link #getFatalErrors()}
   * will return the errors or {@link #getException()} will be set to the
   * Exception that was thrown by the compiler.
   */
  public boolean didBuild() {
    return fatalErrors.isEmpty() && exception == null;
  }

  /**
   * The time (in milliseconds) that elapsed during the compiler invocation.
   */
  public long getDuration() {
    return duration;
  }

  public List<CompileError> getFatalErrors() {
    return fatalErrors;
  }

  public List<CompileError> getTypeErrors() {
    return typeErrors;
  }

  public Throwable getException() {
    return exception;
  }

  public String getJavaScript() {
    return binary;
  }

  public List<CompileError> getWarnings() {
    return warnings;
  }
}
