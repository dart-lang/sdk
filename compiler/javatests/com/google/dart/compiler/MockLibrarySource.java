// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import java.io.Reader;
import java.io.StringReader;
import java.util.ArrayList;
import java.util.List;

/**
 * Testing implementation of {@link LibrarySource}.
 */
public class MockLibrarySource extends SourceTest implements LibrarySource {

  private final static String TEST_APP_NAME = "Test_app";

  private final List<LibrarySource> imports = new ArrayList<LibrarySource>();
  private final List<DartSource> sources = new ArrayList<DartSource>();

  public MockLibrarySource() {
    super(TEST_APP_NAME);
  }

  @Override
  public Reader getSourceReader() {
    ArrayList<String> libNames = new ArrayList<String>();
    for (LibrarySource lib : imports) {
      libNames.add(lib.getName());
    }
    ArrayList<String> sourceNames = new ArrayList<String>();
    for (DartSource source : sources) {
      sourceNames.add(source.getName());
    }
    // Passing null for the entryPoint, assuming the source already contains a
    // toplevel main() or is a library that doesn't require an entryPoint.
    return new StringReader(DefaultLibrarySource.generateSource(
        getName(), libNames, sourceNames, null));
  }

  @Override
  public LibrarySource getImportFor(String relPath) {
    for (LibrarySource lib : imports) {
      if (lib.getName().equals(relPath)) {
        return lib;
      }
    }
    throw new RuntimeException("Cannot find import for " + relPath);
  }

  @Override
  public DartSource getSourceFor(String relPath) {
    if (relPath.equals(TEST_APP_NAME)) {
      return new MockDartSource(this);
    }
    for (DartSource source : sources) {
      if (source.getName().equals(relPath)) {
        return source;
      }
    }
    throw new RuntimeException("Cannot find source for " + relPath);
  }

  public void addSource(DartSource src) {
    sources.add(src);
  }

  private static class MockDartSource extends SourceTest implements DartSource {
    final MockLibrarySource libSource;
    public MockDartSource(MockLibrarySource libSource) {
      super(libSource.getName());
      this.libSource = libSource;
    }

    @Override
    public Reader getSourceReader() {
      return libSource.getSourceReader();
    }

    @Override
    public LibrarySource getLibrary() {
      return libSource;
    }

    @Override
    public String getRelativePath() {
      return libSource.getUri().toString();
    }
  }
}
