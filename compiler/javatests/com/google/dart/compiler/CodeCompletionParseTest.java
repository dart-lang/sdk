// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.dart.compiler.ast.LibraryUnit;

/**
 * Tests the use of the parser and analysis phases as used by the IDE for code
 * completion.
 */
public class CodeCompletionParseTest extends CompilerTestCase {

  public void test1() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(makeCode(
        "class CellLocation {",
        "  int _field1;",
        "  String _field2;",
        "",
        "  CellLoc", // cursor
        "",
        "  int hashCode() {",
        "     return _field1 * 31 ^ _field2.hashCode();",
        "  }",
        "}"));
    LibraryUnit lib = result.getLibraryUnitResult();
    assertNotNull(lib);
  }

  public void test2() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(makeCode(
        "doFoo() {",
        "  new ", // cursor
        "}"));
    LibraryUnit lib = result.getLibraryUnitResult();
    assertNotNull(lib);
  }

  public void test3() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(makeCode(
        "class Foo {",
        "  static final Bar b = const ", // cursor
        "}",
        "",
        "class Bar {",
        "  factory Bar() {}",
        "}"));
    LibraryUnit lib = result.getLibraryUnitResult();
    assertNotNull(lib);
  }

  public void test4() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(makeCode(
        "foo() {",
        "  int SEED;",
        "  for (int i = 0; i < S)", // cursor before )
        "}"));
    LibraryUnit lib = result.getLibraryUnitResult();
    assertNotNull(lib);
  }

  public void test5() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(makeCode(
        "ckass Sunflower {",
        "  static final int SEED_RADIUS = 2;",
        "  static final int SCALE_FACTOR = 4;",
        "  static final num PI2 = Math.PI * 2;",
        "  static final num PI4 = M", // cursor
        "}"));
    LibraryUnit lib = result.getLibraryUnitResult();
    assertNotNull(lib);
  }

  public void test6() throws Exception {
    AnalyzeLibraryResult result = analyzeLibrary(makeCode(
        "class Sunflower {",
        "  static final int SEED_RADIUS = 2;",
        "  static final int SCALE_FACTOR = 4;",
        "  static final num PI2 = Math.PI * 2;",
        "  static final num PI4 = M", // cursor
        "}"));
    LibraryUnit lib = result.getLibraryUnitResult();
    assertNotNull(lib);
  }
}
