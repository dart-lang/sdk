// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.testing;

import com.google.dart.compiler.CommandLineOptions.CompilerOptions;
import com.google.dart.compiler.CompilerConfiguration;
import com.google.dart.compiler.DartCompilationPhase;
import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.PackageLibraryManager;
import com.google.dart.compiler.UrlLibrarySource;
import com.google.dart.compiler.metrics.CompilerMetrics;

import java.io.File;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.Collections;
import java.util.List;

/**
 * A mock configuration for use in tests.
 */
public class TestCompilerConfiguration implements CompilerConfiguration {
  private final CompilerOptions compilerOptions = new CompilerOptions();
  private final PackageLibraryManager systemLibraryManager =
      new PackageLibraryManager();

  @Override
  public boolean developerModeChecks() {
    return false;
  }

  @Override
  public boolean warningsAreFatal() {
    return false;
  }

  @Override
  public boolean typeErrorsAreFatal() {
    return false;
  }

  @Override
  public boolean resolveDespiteParseErrors() {
    return true;
  }

  @Override
  public boolean incremental() {
    return false;
  }

  @Override
  public List<DartCompilationPhase> getPhases() {
    return Collections.emptyList();
  }

  @Override
  public File getOutputDirectory() {
    throw new AssertionError();
  }

  @Override
  public CompilerMetrics getCompilerMetrics() {
    return null;
  }

  @Override
  public String getJvmMetricOptions() {
    return null;
  }

  @Override
  public LibrarySource getSystemLibraryFor(String importSpec) {
    URI systemUri;
    try {
      systemUri = new URI(importSpec);
    } catch (URISyntaxException e) {
      throw new RuntimeException(e);
    }
    return new UrlLibrarySource(systemUri, this.systemLibraryManager);
  }

  @Override
  public CompilerOptions getCompilerOptions() {
    return compilerOptions;
  }

  @Override
  public ErrorFormat printErrorFormat() {
    return ErrorFormat.MACHINE;
  }

  @Override
  public PackageLibraryManager getSystemLibraryManager() {
    return systemLibraryManager;
  }
}
