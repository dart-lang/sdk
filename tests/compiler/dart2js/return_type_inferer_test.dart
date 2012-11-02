// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../../sdk/lib/_internal/compiler/implementation/ssa/ssa.dart';

import 'compiler_helper.dart';

const String TEST_ONE = r"""
  f(p) { if (p == null) return p; else return p; }
  main() { f("s"); }
""";

const String TEST_TWO = r"""
  f(p) { if (p == null) return p; else return p; }
  main() { f(1); }
""";

const String TEST_THREE = r"""
  f(p) { if (p == null) return p; else return p; }
  main() { f(1); f(2); }
""";

const String TEST_FOUR = r"""
  f(p) { if (p == null) return p; else return p; }
  main() { f(1.1); }
""";

const String TEST_FIVE = r"""
  f(p) { if (p == null) return p; else return p; }
  main() { f(1); f(2.2); }
""";

const String TEST_SIX = r"""
  f(p) { if (p == null) return p; else return p; }
  main() { f(1.1); f(2); }
""";

const String TEST_SEVEN = r"""
  f(p) { if (p == null) return p; else return p; }
  main() { f(1); f("s"); }
""";

const String TEST_EIGHT = r"""
  f(p1, p2) {
    if (p1 == null) return p1;
    else return p1;
  }
  main() { f(1, 2); f(1, "s"); }
""";

const String TEST_NINE = r"""
  f(p1, p2) {
    if (p1 == null) return p1;
    else return p1;
  }
  main() { f("s", 2); f(1, "s"); }
""";

const String TEST_TEN = r"""
  f(p) { if (p == null) return p; else return p; }
  g(p) { if (p == null) return p; else return p; }
  main() { f(1); g(f); }
""";

void runTest(String test, [HType expectedType = HType.UNKNOWN]) {
  compileAndCheck(
    test,
    'f',
    (compiler, x) {
      var backend = compiler.backend;
      HType type =
          backend.optimisticReturnTypesWithRecompilationOnTypeChange(null, x);
      Expect.equals(expectedType, type);
  });
}

void test() {
  runTest(TEST_ONE, HType.STRING);
  runTest(TEST_TWO, HType.INTEGER);
  runTest(TEST_THREE, HType.INTEGER);
  runTest(TEST_FOUR, HType.DOUBLE);
  runTest(TEST_FIVE, HType.NUMBER);
  runTest(TEST_SIX, HType.NUMBER);
  runTest(TEST_SEVEN);
  runTest(TEST_EIGHT, HType.INTEGER);
  runTest(TEST_NINE);
  runTest(TEST_TEN);
}

void main() {
  test();
}
