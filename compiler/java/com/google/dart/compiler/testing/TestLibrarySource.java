// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.testing;

import com.google.dart.compiler.DartSource;
import com.google.dart.compiler.LibrarySource;

import java.io.Reader;
import java.io.StringReader;
import java.net.URI;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * A mock library source for use in tests.
 */
public class TestLibrarySource implements LibrarySource {
  private abstract class TestDartSource implements DartSource {
    private final String srcName;
    private final URI srcUri;

    private TestDartSource(String name, URI uri) {
      this.srcName = name;
      this.srcUri = uri;
    }

    @Override
    public String getUniqueIdentifier() {
      return srcUri.toString();
    }

    @Override
    public URI getUri() {
      return srcUri;
    }

    @Override
    public String getName() {
      return srcName;
    }

    @Override
    public boolean exists() {
      return true;
    }

    @Override
    public long getLastModified() {
      return 0;
    }

    @Override
    public LibrarySource getLibrary() {
      return TestLibrarySource.this;
    }

    @Override
    public String getRelativePath() {
      return srcName;
    }
  }

  private final String name;
  private URI uri;
  private final Map<String, DartSource> sourceMap = new LinkedHashMap<String, DartSource>();

  public TestLibrarySource(String name) {
    this.name = name;
    uri = URI.create(name);
  }

  @Override
  public String getUniqueIdentifier() {
    return uri.toString();
  }

  @Override
  public URI getUri() {
    return uri;
  }

  @Override
  public Reader getSourceReader() {
    StringBuilder sb = new StringBuilder();
    sb.append("library ");
    sb.append(name);
    sb.append(";\n");
    for (DartSource source : sourceMap.values()) {
      sb.append("part '");
      sb.append(source.getName());
      sb.append("';\n");
    }
    return new StringReader(sb.toString());
  }

  /**
   * Add a source file to this library.
   * @param name the relative name (uri) of the source file.
   * @param sourceLines the lines of the source (automatically separated by newlines)
   */
  public DartSource addSource(final String name, String... sourceLines) {
    StringBuilder sb = new StringBuilder();
    for (String line : sourceLines) {
      sb.append(line);
      sb.append("\n");
    }
    final String source = sb.toString();
    final URI uri = URI.create(name);
    DartSource dartSource = new TestDartSource(name, uri){
      @Override
      public Reader getSourceReader() {
        return new StringReader(source);
      }};
    return sourceMap.put(dartSource.getName(), dartSource);
  }

  @Override
  public String getName() {
    return name;
  }

  @Override
  public boolean exists() {
    return true;
  }

  @Override
  public long getLastModified() {
    return 0;
  }

  @Override
  public DartSource getSourceFor(String relPath) {
    if (!name.equals(relPath)) {
      return sourceMap.get(relPath);
    }
    
    // Return DartSource for the library itself
    return new TestDartSource(name, uri) {
      @Override
      public Reader getSourceReader() {
        return TestLibrarySource.this.getSourceReader();
      }
    };
  }

  @Override
  public LibrarySource getImportFor(String relPath) {
    throw new AssertionError(relPath);
  }
}
