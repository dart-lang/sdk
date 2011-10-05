// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart;

import java.io.IOException;
import java.io.Reader;
import java.io.StringReader;
import java.net.URI;
import java.util.Map;

import com.google.common.collect.Maps;
import com.google.dart.compiler.DartSource;
import com.google.dart.compiler.LibrarySource;

/**
 * A local synthetic library.  
 */
public class LibraryFromSources implements LibrarySource, DartSource {
  private final Map<String, LibrarySource> libs = Maps.newHashMap();
  private final Map<String, DartSource> sources = Maps.newHashMap();
  private final Map<String, DartSource> natives = Maps.newHashMap();
  private final String name;

  public LibraryFromSources(String name, LibrarySource... libs) {
    this.name = name;
    for (LibrarySource lib : libs) {
      this.libs.put(lib.getName(), lib);
    }
    sources.put(name, this);
  }

  public void addNative(DartSource source) {
    natives.put(source.getName(), source);
  }

  public void addSource(DartSource source) {
    sources.put(source.getName(), source);
  }

  @Override
  public boolean exists() {
    return true;
  }

  @Override
  public LibrarySource getImportFor(String path) throws IOException {
    return libs.get(path);
  }

  @Override
  public long getLastModified() {
    return 0;
  }

  @Override
  public String getName() {
    return name;
  }

  @Override
  public DartSource getSourceFor(String path) {
    final DartSource source = sources.get(path);
    if (source != null) {
      return source;
    }
    return natives.get(path);
  }

  // TODO(knorton): DefaultLibrarySource has this exact code but it doesn't allow you to specify
  // a list for native sources. Add that functionality and then delegate appropriately.
  @Override
  public Reader getSourceReader() throws IOException {
    final StringBuilder sb = new StringBuilder();
    sb.append("#library('" + name + "');\n");

    for (LibrarySource lib : libs.values()) {
      sb.append("#import('" + lib.getName() + "');\n");
    }
    
    for (DartSource source : sources.values()) {
      sb.append("#source('" + source.getName() + "');\n");
    }

    for (DartSource source : natives.values()) {
      sb.append("#native('" + source.getName() + "');\n");
    }

    return new StringReader(sb.toString());
  }

  @Override
  public URI getUri() {
    return CompileService.uriFor(name);
  }

  @Override
  public LibrarySource getLibrary() {
    return this;
  }

  @Override
  public String getRelativePath() {
    return getName();
  }
}
