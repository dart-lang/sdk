// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import java.io.IOException;
import java.io.Reader;
import java.io.Writer;
import java.net.URI;

/**
 * Abstract class that {@link DartCompiler} consumers can use to specify where
 * generated files are located.
 */
public abstract class DartArtifactProvider {

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
   * @return the reader, or <code>null</code> if there is no such artifact
   */
  public abstract Reader getArtifactReader(Source source, String part, String extension)
      throws IOException;

  /**
   * Gets the {@link URI} for an artifact associated with this source.
   *
   * @param source the source file (not <code>null</code>)
   * @param part a component of the source file to get a reader for (may be empty).
   * @param extension the file extension for this artifact (not
   *          <code>null</code>, not empty)
   */
  public abstract URI getArtifactUri(Source source, String part, String extension);

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
  public abstract Writer getArtifactWriter(Source source, String part, String extension)
      throws IOException;

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
   public abstract boolean isOutOfDate(Source source, Source base, String extension);
}
