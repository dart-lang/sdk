// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.dart.compiler.CommandLineOptions.CompilerOptions;
import com.google.dart.compiler.metrics.CompilerMetrics;
import com.google.dart.compiler.resolver.CompileTimeConstantAnalyzer;
import com.google.dart.compiler.resolver.Resolver;
import com.google.dart.compiler.type.TypeAnalyzer;

import java.io.File;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.List;

/**
 * A configuration for the Dart compiler specifying which phases will be executed.
 */
public class DefaultCompilerConfiguration implements CompilerConfiguration {

  private final CompilerOptions compilerOptions;

  private final CompilerMetrics compilerMetrics;

  private final SystemLibraryManager systemLibraryManager;

  /**
   * A default configuration.
   */
  public DefaultCompilerConfiguration() {
    this(new CompilerOptions());
  }

  /**
   * A new instance with the specified {@link CompilerOptions}.
   */
  public DefaultCompilerConfiguration(CompilerOptions compilerOptions) {
    this(compilerOptions, new SystemLibraryManager(compilerOptions.getDartSdkPath(),
                                                   compilerOptions.getPlatformName()));
  }

  /**
   * A new instance with the specified options and system library manager.
   */
  public DefaultCompilerConfiguration(CompilerOptions compilerOptions,
      SystemLibraryManager libraryManager) {
    this.compilerOptions = compilerOptions;
    this.compilerMetrics = compilerOptions.showMetrics() ? new CompilerMetrics() : null;
    this.systemLibraryManager = libraryManager;
  }

  @Override
  public List<DartCompilationPhase> getPhases() {
    List<DartCompilationPhase> phases = new ArrayList<DartCompilationPhase>();
    phases.add(new CompileTimeConstantAnalyzer.Phase());
    phases.add(new Resolver.Phase());
    phases.add(new TypeAnalyzer());
    return phases;
  }

  @Override
  public boolean developerModeChecks() {
    return compilerOptions.developerModeChecks();
  }

  @Override
  public CompilerMetrics getCompilerMetrics() {
    return compilerMetrics;
  }

  @Override
  public String getJvmMetricOptions() {
    return compilerOptions.getJvmMetricOptions();
  }

  @Override
  public boolean typeErrorsAreFatal() {
    return compilerOptions.typeErrorsAreFatal();
  }

  @Override
  public boolean warningsAreFatal() {
    return compilerOptions.warningsAreFatal();
  }

  @Override
  public boolean resolveDespiteParseErrors() {
    return compilerOptions.resolveDespiteParseErrors();
  }

  @Override
  public boolean incremental() {
    return compilerOptions.buildIncrementally();
  }

  @Override
  public File getOutputDirectory() {
    return compilerOptions.getWorkDirectory();
  }

  @Override
  public LibrarySource getSystemLibraryFor(String importSpec) {
    URI systemUri;
    try {
      systemUri = new URI(importSpec);
    } catch (URISyntaxException e) {
      throw new RuntimeException(e);
    }

    // Verify the dart system library exists
    if( null == this.systemLibraryManager.expandRelativeDartUri(systemUri) ) {
      return null;
    }
    return new UrlLibrarySource(systemUri, this.systemLibraryManager);
  }

  @Override
  public CompilerOptions getCompilerOptions() {
    return compilerOptions;
  }

  @Override
  public ErrorFormat printErrorFormat() {
    return compilerOptions.printErrorFormat();
  }
}
