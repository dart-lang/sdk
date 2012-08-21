// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.dart.compiler.CommandLineOptions.CompilerOptions;
import com.google.dart.compiler.metrics.CompilerMetrics;

import java.io.File;
import java.util.List;

/**
 * Provides a way to override a specific method of an existing instance of a CompilerConfiguration.
 *
 * @author zundel@google.com (Eric Ayers)
 */
public class DelegatingCompilerConfiguration implements CompilerConfiguration {

  private CompilerConfiguration delegate;

  public DelegatingCompilerConfiguration(CompilerConfiguration delegate) {
    this.delegate = delegate;
  }

  @Override
  public boolean developerModeChecks() {
    return delegate.developerModeChecks();
  }

  @Override
  public List<DartCompilationPhase> getPhases() {
    return delegate.getPhases();
  }

  @Override
  public CompilerMetrics getCompilerMetrics() {
    return delegate.getCompilerMetrics();
  }

  @Override
  public String getJvmMetricOptions() {
    return delegate.getJvmMetricOptions();
  }

  @Override
  public boolean typeErrorsAreFatal() {
    return delegate.typeErrorsAreFatal();
  }

  @Override
  public boolean warningsAreFatal() {
    return delegate.warningsAreFatal();
  }

  @Override
  public boolean resolveDespiteParseErrors() {
    return delegate.resolveDespiteParseErrors();
  }

  @Override
  public boolean incremental() {
    return delegate.incremental();
  }

  @Override
  public File getOutputDirectory() {
    return delegate.getOutputDirectory();
  }

  @Override
  public LibrarySource getSystemLibraryFor(String importSpec) {
    return delegate.getSystemLibraryFor(importSpec);
  }

  @Override
  public CompilerOptions getCompilerOptions() {
    return delegate.getCompilerOptions();
  }

  @Override
  public ErrorFormat printErrorFormat() {
    return delegate.printErrorFormat();
  }

  @Override
  public PackageLibraryManager getPackageLibraryManager() {
    return delegate.getPackageLibraryManager();
  }
}
