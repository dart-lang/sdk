// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import java.io.Reader;
import java.io.StringReader;
import java.net.URL;

public class DartSourceTest extends SourceTest implements DartSource {
  private final String path;
  private final String src;
  private final LibrarySource lib;

  public DartSourceTest(Class<?> base, String path, LibrarySource lib) {
    super(path);

    this.path = path;
    this.lib = lib;
    URL url = CompilerTestCase.inputUrlFor(base, path);
    src = CompilerTestCase.readUrl(url);
  }

  public DartSourceTest(String path, String source, LibrarySource lib) {
    super(path + ".dart");

    this.path = path;
    this.src = source;
    this.lib = lib;
  }

  @Override
  public LibrarySource getLibrary() {
    return lib;
  }

  @Override
  public String getName() {
    return path;
  }

  @Override
  public Reader getSourceReader() {
    return new StringReader(src);
  }

  @Override
  public String getRelativePath() {
    return path;
  }
}
