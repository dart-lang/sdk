// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.metrics.CompilerMetrics;

import java.io.IOException;
import java.io.Reader;
import java.io.Writer;
import java.net.URI;

/**
 * An interface used internally by the {@link DartCompiler} and implementers of
 * {@link Backend} for determining where an artifact should be generated and
 * providing feedback during the compilation process. This is an internal
 * compiler construct and as such should not be instantiated or implemented by
 * those outside the compiler itself.
 */
public interface DartCompilerContext {

  /**
   * Parse the application being compiled and return the result. The "application unit" is a
   * library that specifies an entry-point.
   * 
   * This method will be removed in favor of {@link #getAppLibraryUnit()}.
   *
   * @return the parsed result (not <code>null</code>)
   */
  LibraryUnit getApplicationUnit();

  /**
   * Parse the application being compiled and return the result. The "app" library unit is a
   * library that specifies an entry-point.
   *
   * @return the parsed result (not <code>null</code>)
   */
  LibraryUnit getAppLibraryUnit();

  /**
   * Parse the specified library and return the result.
   *
   * @param lib the library to parse (not <code>null</code>)
   * @return the parsed result (not <code>null</code>)
   */
  LibraryUnit getLibraryUnit(LibrarySource lib);

  /**
   * Called by the compiler when a compilation error has occurred in a Dart
   * file.
   *
   * @param event the event information (not <code>null</code>)
   */
  void compilationError(DartCompilationError event);

  /**
   * Called by the compiler when a (non-fatal) type error has been detected.
   *
   * @param event the event information (not <code>null</code>)
   */
  void typeError(DartCompilationError event);

  /**
   * Gets a reader for an artifact associated with the specified source, which
   * must have been written to {@link #getArtifactWriter(Source, String, String)}. The
   * caller is responsible for closing the reader. Only one artifact may be
   * associated with the given extension.
   *
   * @param source the source file (not <code>null</code>)
   * @param part a component of the source file to get a reader for (may be empty).
   * @param extension the file extension for this artifact (not
   *          <code>null</code>, not empty)
   * @return the reader, or <code>null</code> if no such artifact exists
   */
  Reader getArtifactReader(Source source, String part, String extension) throws IOException;

  /**
   * Gets the {@link URI} for an artifact associated with this source.
   * 
   * @param source the source file (not <code>null</code>)
   * @param part a component of the source file to get a reader for (may be empty).
   * @param extension the file extension for this artifact (not
   *          <code>null</code>, not empty)
   */
  URI getArtifactUri(DartSource source, String part, String extension);

  /**
   * Gets a writer for an artifact associated with this source. The caller is
   * responsible for closing the writer. Only one artifact may be associated
   * with the given extension.
   *
   * @param source the source file (not <code>null</code>)
   * @param part a component of the source file to get a reader for (may be empty).
   * @param extension the file extension for this artifact (not
   *          <code>null</code>, not empty)
   */
  Writer getArtifactWriter(Source source, String part, String extension) throws IOException;

  /**
   * Determines whether an artifact for the specified source is out of date
   * with respect to some other source.
   *
   * @param source the source file to check (not <code>null</code>)
   * @param base the artifact's base source (not <code>null</code>)
   * @param extension the file extension for this artifact (not
   *          <code>null</code>, not empty)
   * @return <code>true</code> if out of date
   */
  boolean isOutOfDate(Source source, Source base, String extension);

  /**
   * Returns the {@link CompilerMetrics} instance or <code>null</code> if we should not record
   * metrics.
   *
   * @return the metrics instance, <code>null</code> if metrics should not be recorded
   */
  CompilerMetrics getCompilerMetrics();

  boolean shouldWarnOnNoSuchType();

  /**
   * Returns the {@link CompilerConfiguration} instance.
   * @return the compiler configuration instance.
   */
  CompilerConfiguration getCompilerConfiguration();

  /**
   * Return the system library corresponding to the specified "dart:<libname>" spec.
   */
  LibrarySource getSystemLibraryFor(String importSpec);
}
