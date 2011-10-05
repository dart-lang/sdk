// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart;

import com.google.dart.compiler.DartSource;
import com.google.dart.compiler.LibrarySource;

import java.io.IOException;
import java.io.Reader;
import java.io.StringReader;
import java.net.URI;

public class SourceFromString implements DartSource {
  private final String name;
  private final String source;
  private final LibrarySource library;
  
  SourceFromString(LibrarySource library, String name, String source) {
    this.name = name;
    this.source = source;
    this.library = library;
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
    return library;
  }

  @Override
  public String getName() {
    return name;
  }

  @Override
  public String getRelativePath() {
    return name;
  }

  @Override
  public Reader getSourceReader() throws IOException {
    return new StringReader(source);
  }

  @Override
  public URI getUri() {
    return CompileService.uriFor(name);
  }
}
