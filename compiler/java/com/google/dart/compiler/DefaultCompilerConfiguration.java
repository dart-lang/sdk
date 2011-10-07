// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.dart.compiler.CommandLineOptions.CompilerOptions;
import com.google.dart.compiler.backend.doc.DartDocumentationGenerator;
import com.google.dart.compiler.backend.isolate.DartIsolateStubGenerator;
import com.google.dart.compiler.backend.js.ClosureJsBackend;
import com.google.dart.compiler.backend.js.JavascriptBackend;
import com.google.dart.compiler.metrics.CompilerMetrics;
import com.google.dart.compiler.resolver.Resolver;
import com.google.dart.compiler.type.TypeAnalyzer;

import java.io.File;
import java.io.FileNotFoundException;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * A configuration for the Dart compiler specifying which phases
 * and backends will be executed.
 *
 * @author sigmund@google.com (Siggi Cherem)
 */
public class DefaultCompilerConfiguration implements CompilerConfiguration {

  private List<Backend> backends;

  private final CompilerOptions compilerOptions;

  private final CompilerMetrics compilerMetrics;

  private final SystemLibraryManager systemLibraryManager;

  /**
   * A default configuration with the {@link JavascriptBackend}
   */
  public DefaultCompilerConfiguration() {
    this(new JavascriptBackend());
  }

  private static Backend selectBackend(CompilerOptions compilerOptions)
      throws FileNotFoundException {
    if (compilerOptions.generateDocumentation()) {
      return new DartDocumentationGenerator(compilerOptions.getDocumentationOutputDirectory(),
                                            compilerOptions.getDocumentationLibrary());
    } else if (!compilerOptions.getIsolateStubClasses().isEmpty()) {
      return new DartIsolateStubGenerator(compilerOptions.getIsolateStubClasses(),
                                          compilerOptions.getIsolateStubOutputFile());
    } else if (compilerOptions.shouldOptimize()) {
      return new ClosureJsBackend(compilerOptions.generateHumanReadableOutput());
    } else {
      return new JavascriptBackend();
    }
  }

  /**
   * A new instance with the specified {@link CompilerOptions}
   * @throws FileNotFoundException
   */
  public DefaultCompilerConfiguration(CompilerOptions compilerOptions)
      throws FileNotFoundException {
    this (selectBackend(compilerOptions), compilerOptions);
  }

  /**
   * A new instance with the specified {@link Backend}
   */
  public DefaultCompilerConfiguration(Backend backend) {
    this(new CompilerOptions(), backend);
  }

  /**
   * A new instance with the specified {@link Backend} and {@link CompilerOptions}
   */
  public DefaultCompilerConfiguration(Backend backend, CompilerOptions compilerOptions) {
    this(compilerOptions, backend);
  }

  /**
   * A new instance with the specified list of {@link Backend}
   */
  public DefaultCompilerConfiguration(Backend... backends) {
    this(new CompilerOptions(), backends);
  }

  /**
   * A new instance with the specified list of {@link Backend}
   */
  public DefaultCompilerConfiguration(CompilerOptions compilerOptions, Backend... backends) {
    this(compilerOptions, new SystemLibraryManager(), backends);
  }

  /**
   * A new instance with the specified options, system library manager, and default {@link Backend
   * backends}.
   */
  public DefaultCompilerConfiguration(CompilerOptions compilerOptions,
      SystemLibraryManager libraryManager) throws FileNotFoundException {
    this(compilerOptions, libraryManager, selectBackend(compilerOptions));
  }

  /**
   * A new instance with the specified options, system library manager, and list of {@link Backend
   * backends}.
   */
  public DefaultCompilerConfiguration(CompilerOptions compilerOptions, SystemLibraryManager libraryManager, Backend... backends) {
    this.backends = Arrays.asList(backends);
    this.compilerOptions = compilerOptions;
    this.compilerMetrics = compilerOptions.showMetrics() ?
        new CompilerMetrics() : null;
    this.systemLibraryManager = libraryManager;
  }

  @Override
  public List<DartCompilationPhase> getPhases() {
    List<DartCompilationPhase> phases = new ArrayList<DartCompilationPhase>();
    phases.add(new Resolver.Phase());
    phases.add(new TypeAnalyzer());
    return phases;
  }

  @Override
  public List<Backend> getBackends() {
    return backends;
  }

  @Override
  public boolean shouldOptimize() {
    return compilerOptions.shouldOptimize();
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
    return false;
  }

  @Override
  public boolean incremental() {
    return compilerOptions.incremental();
  }

  @Override
  public File getOutputFilename() {
    return compilerOptions.getOutputFilename();
  }

  @Override
  public File getOutputDirectory() {
    return compilerOptions.getWorkDirectory();
  }

  @Override
  public boolean checkOnly() {
    return compilerOptions.checkOnly();
  }

  @Override
  public boolean expectEntryPoint() {
    return false;
  }

  @Override
  public boolean allowNoSuchType() {
    return false;
  }

  @Override
  public boolean collectComments() {
    return compilerOptions.generateDocumentation();
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
}