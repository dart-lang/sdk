// Copyright (c) 2012, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.common.base.Objects;

/**
 * Information about import - prefix and {@link LibraryUnit}.
 */
public class LibraryImport {
  private final String prefix;
  private final LibraryUnit library;

  public LibraryImport(String prefix, LibraryUnit library) {
    this.prefix = prefix;
    this.library = library;
  }

  @Override
  public int hashCode() {
    return Objects.hashCode(prefix, library);
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof LibraryImport) {
      LibraryImport other = (LibraryImport) obj;
      return Objects.equal(prefix, other.prefix) && Objects.equal(library, other.library);
    }
    return false;
  }

  public String getPrefix() {
    return prefix;
  }

  public LibraryUnit getLibrary() {
    return library;
  }
}
