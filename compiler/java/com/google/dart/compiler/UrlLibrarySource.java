// Copyright (c) 2012, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler;

import java.io.File;
import java.net.URI;

/**
 * A {@link LibrarySource} backed by a URL.
 */
public class UrlLibrarySource extends UrlSource implements LibrarySource {
  
  public UrlLibrarySource(URI uri, PackageLibraryManager slm) {
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
  public LibrarySource getImportFor(String relPath) {
    if (relPath == null || relPath.isEmpty()) {
      return null;
    }
    try {
      // Force the creation of an escaped relative URI to deal with spaces, etc.
      URI uri = getUri().resolve(new URI(null, null, relPath, null, null)).normalize();
      String path = uri.getPath();
      // Resolve relative reference out of one system library into another
      if (PackageLibraryManager.isDartUri(uri)) {
        if (path != null && path.startsWith("/..")) {
          URI fileUri = packageLibraryManager.resolveDartUri(uri);
          URI shortUri = packageLibraryManager.getShortUri(fileUri);
          if (shortUri != null) {
            uri = shortUri;
          }
        }
      } else if (PackageLibraryManager.isPackageUri(uri)) {
        URI fileUri = packageLibraryManager.resolveDartUri(uri);
        if (fileUri != null) {
          uri = fileUri;
        }
      } else if (!resourceExists(uri)) {
        // resolve against package root directories to find file
        uri = packageLibraryManager.findExistingFileInPackages(uri);
      }

      return createLibrarySource(uri, packageLibraryManager);
    } catch (Throwable e) {
      return null;
    }
  }

  @Override
  public DartSource getSourceFor(final String relPath) {
    if (relPath == null || relPath.isEmpty()) {
      return null;
    }
    try {
      // Force the creation of an escaped relative URI to deal with spaces, etc.
      URI uri = getUri().resolve(new URI(null, null, relPath, null, null)).normalize();
      if (PackageLibraryManager.isPackageUri(uri)) {
        URI fileUri = packageLibraryManager.resolveDartUri(uri);
        if (fileUri != null) {
          uri = fileUri;
        }
      }
      return createDartSource(uri, relPath, this, packageLibraryManager);
    } catch (Throwable e) {
      return null;
    }
  }

  /**
   * Create a URL library source. 
   * 
   * (Clients can override.)
   * 
   * @param uri the URI of the library
   * @param relPath relative path to the dart source
   * @param libSource the library source
   * @param packageManager the package library manager
   * @return the resulting dart source
   */
  protected UrlDartSource createDartSource(URI uri, String relPath, UrlLibrarySource libSource, PackageLibraryManager packageManager) {
    return new UrlDartSource(uri, relPath, libSource, packageManager);
  }

  /**
   * Create a URL library source. 
   * 
   * (Clients can override.)
   * 
   * @param uri the URI of the library
   * @return the resulting library source
   */
  protected UrlLibrarySource createLibrarySource(URI uri, PackageLibraryManager packageManager) {
    return new UrlLibrarySource(uri, packageManager);
  }
  
  /**
   * Check if a resource exists at this URI.
   * 
   * (Clients can override.)
   * 
   * @param uri the URI to test
   * @return <code>true</code> if a resource exists at this URI, <code>false</code> otherwise
   */
  protected boolean resourceExists(URI uri) {
    String path = uri.getPath();
    return path == null || new File(path).exists();
  }
  
}
