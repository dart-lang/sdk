// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import java.io.IOException;
import java.io.Reader;
import java.io.StringReader;
import java.net.URL;

public class DartLibrarySourceTest extends SourceTest implements LibrarySource {
  private final String src;
  private final Class<?> base;

  public DartLibrarySourceTest(Class<?> base, String path) {
    super(path);

    this.base = base;
    URL url = CompilerTestCase.inputUrlFor(base, path);
    src = CompilerTestCase.readUrl(url);
  }

  @Override
  public Reader getSourceReader() throws IOException {
    return new StringReader(src);
  }

  @Override
  public LibrarySource getImportFor(String relPath) throws IOException {
    throw new RuntimeException("Unimplemented");
  }

  @Override
  public DartSource getSourceFor(String relPath) {
    return new DartSourceTest(base, relPath, this);
  }
}
