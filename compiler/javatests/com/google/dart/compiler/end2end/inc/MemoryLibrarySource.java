// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler.end2end.inc;

import com.google.common.collect.Maps;
import com.google.dart.compiler.DartSource;
import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.UrlDartSource;

import java.io.IOException;
import java.io.Reader;
import java.io.StringReader;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.Map;

/**
 * {@link LibrarySource} which provides content for all {@link Source}s from memory.
 */
public class MemoryLibrarySource implements LibrarySource {
  private final String libName;
  private final String libContent;
  private final Map<String, String> sourceContentMap = Maps.newHashMap();
  private final Map<String, Long> sourceLastModifiedMap = Maps.newHashMap();

  public MemoryLibrarySource(String libName, String libContent) throws URISyntaxException {
    this.libName = libName;
    this.libContent = libContent;
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
    return 0;
  }
  
  @Override
  public Reader getSourceReader() throws IOException {
    return new StringReader(libContent);
  }

  @Override
  public LibrarySource getImportFor(String relPath) throws IOException {
    // Not implemented for now, tests which use it don't work with imports.
    return null;
  }

  @Override
  public DartSource getSourceFor(final String relPath) {
    final String content;
    final Long sourceLastModified;
    if (sourceContentMap.containsKey(relPath)) {
      content = sourceContentMap.get(relPath);
      sourceLastModified = sourceLastModifiedMap.get(relPath);
    } else {
      content = "";
      sourceLastModified = Long.valueOf(0);
    }
    // Return fake UrlDateSource with in-memory content.
    URI uri = URI.create(relPath);
    return new UrlDartSource(uri, relPath, this) {
      @Override
      public String getName() {
        return relPath;
      }

      @Override
      public boolean exists() {
        return true;
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
  }

  /**
   * Sets the given content for the source.
   */
  public void setContent(String relPath, String content) {
    sourceContentMap.put(relPath, content);
    sourceLastModifiedMap.put(relPath, System.currentTimeMillis());
  }
}
