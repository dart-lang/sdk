// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.runner;

import com.google.dart.compiler.DartSource;
import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.UrlDartSource;
import com.google.dart.compiler.UrlSource;

import java.net.URISyntaxException;

class BundleLibrarySource extends UrlSource implements LibrarySource {

  private final class BundleDartSource extends UrlDartSource {
    private BundleDartSource(ClassLoader loader, String basePath, String filename)
        throws URISyntaxException {
      super(loader.getResource(basePath + filename).toURI(), filename, BundleLibrarySource.this);
    }

    @Override
    public String getName() {
      return basePath + getRelativePath();
    }
  }

  private final ClassLoader loader;
  private final String basePath;
  private final String filename;

  public BundleLibrarySource(ClassLoader loader, String basePath, String filename)
      throws URISyntaxException {
    super(loader.getResource(basePath + filename).toURI());
    this.loader = loader;
    this.basePath = basePath;
    this.filename = filename;
  }

  @Override
  public LibrarySource getImportFor(String filename) {
    try {
      return new BundleLibrarySource(loader, basePath, filename);
    } catch (URISyntaxException e) {
      throw new AssertionError();
    }
  }

  @Override
  public DartSource getSourceFor(final String relPath) {
    try {
      return new BundleDartSource(loader, basePath, relPath);
    } catch (URISyntaxException e) {
      throw new AssertionError(e);
    }
  }

  @Override
  public String getName() {
    return basePath + filename;
  }
}
