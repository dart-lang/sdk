// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
package com.google.dart.compiler.resolver;

import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.MockLibrarySource;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.LibraryUnit;

/**
 * Testing support for {@link LibraryUnit}.
 */
public final class MockLibraryUnit {
  /**
   * @return the mock {@link LibraryUnit}.
   */
  public static LibraryUnit create() {
    LibrarySource librarySource = new MockLibrarySource();
    return new LibraryUnit(librarySource);
  }

  /**
   * Creates the mock {@link LibraryUnit} and sets it for given {@link DartUnit}.
   * 
   * @return the mock {@link LibraryUnit}.
   */
  public static LibraryUnit create(DartUnit unit) {
    LibraryUnit libraryUnit = create();
    unit.setLibrary(libraryUnit);
    return libraryUnit;
  }
}
