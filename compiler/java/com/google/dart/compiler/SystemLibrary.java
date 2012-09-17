// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import java.io.File;
import java.net.URI;
import java.net.URISyntaxException;

/**
 * A library accessible via the "dart:<libname>.lib" protocol.
 */
public class SystemLibrary {

  private final String shortName;
  private final String host;
  private final String pathToLib;
  private final File dirOrZip;
  private String category;
  private boolean documented;
  private boolean implementation;

  /**
   * Define a new system library such that dart:[shortLibName] will automatically be expanded to
   * dart://[host]/[pathToLib]. For example this call
   *
   * <pre>
   *    new SystemLibrary("html.lib", "html", "dart_html.lib");
   * </pre>
   *
   * will define a new system library such that "dart:html.lib" to automatically be expanded to
   * "dart://html/dart_html.lib". The dirOrZip argument is either the root directory or a zip file
   * containing all files for this library.
   */
  public SystemLibrary(String shortName, String host, String pathToLib, File dirOrZip, String category, 
      boolean documented, boolean implementation) {
    this.shortName = shortName;
    this.host = host;
    this.pathToLib = pathToLib;
    this.dirOrZip = dirOrZip;
    this.category = category;
    this.documented = documented;
    this.implementation = implementation;
  }

  public String getCategory() {
    return category;
  }
 
  public boolean isDocumented() {
    return documented;
  }
 
  public boolean isImplementation() {
    return implementation;
  }

  public boolean isShared(){
    return category.equals("Shared");
  }
  
  public String getHost() {
    return host;
  }

  public String getPathToLib() {
    return pathToLib;
  }

  public String getShortName() {
    return shortName;
  }

  public File getLibraryDir() {
    return dirOrZip;
  }

  public URI translateUri(URI dartUri) {
    if (!dirOrZip.exists()) {
      throw new RuntimeException("System library for " + dartUri + " does not exist: " + dirOrZip.getPath());
    }
    try {
      URI dirOrZipURI = dirOrZip.toURI();
      if (dirOrZip.isFile()) {
        return new URI("jar", "file:" + dirOrZipURI.getPath() + "!" + dartUri.getPath(), null);
      } else {
        return dirOrZipURI.resolve("." + dartUri.getPath());
      }
    } catch (URISyntaxException e) {
      throw new AssertionError();
    }
  }
  
  public File getFile() {
    return this.dirOrZip;
  }
}
