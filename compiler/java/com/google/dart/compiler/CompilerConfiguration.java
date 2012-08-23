// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.dart.compiler.CommandLineOptions.CompilerOptions;
import com.google.dart.compiler.metrics.CompilerMetrics;

import java.io.File;
import java.util.List;

/**
 * A configuration for the Dart compiler specifying which phases will be executed.
 */
public interface CompilerConfiguration {

  enum ErrorFormat {
    NORMAL,  // Library/File, line, message
    MACHINE, // All information including severity, subsystem, etc
  }

  List<DartCompilationPhase> getPhases();

  /**
   * Indicates whether developer-mode runtime checks are needed. 
   * @return true if developer-mode checks should be inserted, false if not
   */
  boolean developerModeChecks();

  /**
   * Returns the {@link CompilerMetrics} instance or <code>null</code> if metrics should not be
   * recorded.
   *
   * @return the metrics instance, <code>null</code> if metrics should not be recorded
   */
  CompilerMetrics getCompilerMetrics();

  /**
   * Returns a comma-separated string list of options for displaying jvm metrics.
   * Returns <code>null</code> if jvm metrics are not enabled.
   */
  String getJvmMetricOptions();

  boolean typeErrorsAreFatal();

  boolean warningsAreFatal();

  /**
   * Returns <code>true</code> if the compiler should try to resolve
   * even after having seen parse-errors.
   */
  boolean resolveDespiteParseErrors();

  /**
   * Temporary flag to turn on incremental compilation. This will be removed once we're certain
   * incremental compilation is correct.
   */
  boolean incremental();

  /**
   * The work directory where incremental build output is stored between invocations.
   */
  File getOutputDirectory();

  /**
   * Returns the error formatting the compiler should print with
   */
  ErrorFormat printErrorFormat();

  /**
   * Return the system library corresponding to the specified "dart:<libname>" spec.
   */
  LibrarySource getSystemLibraryFor(String importSpec);

  /**
   * Return the system library manager 
   */
  public PackageLibraryManager getPackageLibraryManager();
  
  /**
   * Return {@link CompilerOptions} instance.
   * @return command line options passed to the compiler.
   */
  CompilerOptions getCompilerOptions();
}
