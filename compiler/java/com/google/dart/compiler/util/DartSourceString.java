// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.util;

import com.google.dart.compiler.DartSource;
import com.google.dart.compiler.LibrarySource;

import java.io.Reader;
import java.io.StringReader;
import java.net.URI;

/**
 * Instances of the class <code>DartSourceString</code> represent a source
 * composed from a string rather than an external file.
 */
public class DartSourceString implements DartSource {
  /**
   * The name of the source being represented.
   */
  private String name;

  /**
   * The source being represented.
   */
  private String source;

  /**
   * Initialize a new Dart source to have the given content.
   * 
   * @param source the source being represented
   */
  public DartSourceString(String name, String source) {
    this.name = name;
    this.source = source;
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
    return null;
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
  public Reader getSourceReader() {
    return new StringReader(source);
  }

  @Override
  public URI getUri() {
    return URI.create(getName()).normalize();
  }
}
