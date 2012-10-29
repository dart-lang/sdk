// Copyright (c) 2012, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler.end2end.inc;

import com.google.common.collect.Maps;
import com.google.dart.compiler.DartSource;
import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.UrlDartSource;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.Reader;
import java.io.StringReader;
import java.net.URI;
import java.util.Map;

/**
 * {@link LibrarySource} which provides content for all {@link Source}s from memory.
 */
public class MemoryLibrarySource implements LibrarySource {
  public static final String IO_EXCEPTION_CONTENT = "simulate-IOException";
  private final String libName;
  private final Map<String, DartSource> sourceMap;
  private final Map<String, String> sourceContentMap;
  private final Map<String, Long> sourceLastModifiedMap;

  public MemoryLibrarySource(String libName) {
    this.libName = libName;
    sourceMap = Maps.newHashMap();
    sourceContentMap = Maps.newHashMap();
    sourceLastModifiedMap = Maps.newHashMap();
  }

  private MemoryLibrarySource(String libName, MemoryLibrarySource parent) {
    this.libName = libName;
    sourceMap = parent.sourceMap;
    sourceContentMap = parent.sourceContentMap;
    sourceLastModifiedMap = parent.sourceLastModifiedMap;
  }

  @Override
  public boolean exists() {
    return true;
  }

  @Override
  public String getName() {
    return libName;
  }

  @Override
  public String getUniqueIdentifier() {
    return libName;
  }

  @Override
  public URI getUri() {
    return URI.create(libName);
  }

  @Override
  public long getLastModified() {
    return sourceLastModifiedMap.get(libName);
  }

  @Override
  public Reader getSourceReader() throws IOException {
    String content = sourceContentMap.get(libName);
    if (IO_EXCEPTION_CONTENT.equals(content)) {
      throw new IOException("simulated");
    }
    if (content == null) {
      throw new FileNotFoundException(libName);
    }
    return new StringReader(content);
  }

  @Override
  public LibrarySource getImportFor(String relPath) throws IOException {
    if (!sourceContentMap.containsKey(relPath)) {
      return null;
    }
    return new MemoryLibrarySource(relPath, this);
  }

  @Override
  public DartSource getSourceFor(final String relPath) {
    DartSource result;
    // check cache
    {
      result = sourceMap.get(relPath);
      if (result != null) {
        return result;
      }
    }
    // prepare content
    final String content = sourceContentMap.get(relPath);
    final Long sourceLastModified = sourceLastModifiedMap.get(relPath);
    // may be does not exist
    if (content == null) {
      return null;
    }
    // Return fake UrlDateSource with in-memory content.
    final URI uri = URI.create(relPath);
    result = new UrlDartSource(uri, relPath, this) {
      @Override
      public String getName() {
        return relPath;
      }

      @Override
      public URI getUri() {
        return uri;
      }

      @Override
      public boolean exists() {
        return content != null;
      }

      @Override
      public long getLastModified() {
        return sourceLastModified.longValue();
      }

      @Override
      public Reader getSourceReader() throws IOException {
        return new StringReader(content);
      }
    };
    sourceMap.put(relPath, result);
    return result;
  }

  /**
   * Sets the given content for the source.
   */
  public void setContent(String relPath, String content) {
    sourceMap.remove(relPath);
    sourceContentMap.put(relPath, content);
    sourceLastModifiedMap.put(relPath, System.currentTimeMillis());
  }
}
