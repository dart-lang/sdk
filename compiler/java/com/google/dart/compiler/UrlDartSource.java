// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import java.io.File;
import java.net.URI;
import java.net.URISyntaxException;

/**
 * A {@link DartSource} backed by a URL.
 */
public class UrlDartSource extends UrlSource implements DartSource {

  private final LibrarySource lib;
  private final String relPath;

  protected UrlDartSource(URI uri, String relPath, LibrarySource lib, PackageLibraryManager slm) {
    super(uri,slm);
    this.relPath = relPath;
    this.lib = lib;
  }

  protected UrlDartSource(URI uri, String relPath, LibrarySource lib) {
    this(uri, relPath, lib, null);
  }

  public UrlDartSource(File file, LibrarySource lib) {
    super(file);
    this.relPath = file.getPath();
    this.lib = lib;
  }

  @Override
  public LibrarySource getLibrary() {
    return lib;
  }

  @Override
  public String getName() {
    try {
      String uriSafeName = new URI(null, null, relPath, null).toString();
      return lib.getName() + "/" + uriSafeName;
    } catch (URISyntaxException e) {
      throw new AssertionError(e);
    }
  }

  @Override
  public String getRelativePath() {
    return relPath;
  }
}
