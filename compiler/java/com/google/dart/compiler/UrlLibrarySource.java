// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler;

import java.io.File;
import java.net.URI;

/**
 * A {@link LibrarySource} backed by a URL.
 */
public class UrlLibrarySource extends UrlSource implements LibrarySource {
  public UrlLibrarySource(URI uri, SystemLibraryManager slm) {
    super(uri, slm);
  }

  public UrlLibrarySource(URI uri) {
    this(uri, null);
  }

  public UrlLibrarySource(File file) {
    super(file);
  }

  @Override
  public String getName() {
    return getUri().toString();
  }

  @Override
  public DartSource getSourceFor(final String relPath) {
    try {
      // Force the creation of an escaped relative URI to deal with spaces, etc.
      URI uri = getUri().resolve(new URI(null, null, relPath, null)).normalize();
      return new UrlDartSource(uri, relPath, this, systemLibraryManager);
    } catch (Throwable e) {
      return null;
    }
  }

  @Override
  public LibrarySource getImportFor(String relPath) {
    try {
      return new UrlLibrarySource(getUri().resolve(relPath).normalize(), systemLibraryManager);
    } catch (Throwable e) {
      return null;
    }
  }
}
