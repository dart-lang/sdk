// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:uri");

#import("../../../lib/compiler/implementation/ssa/ssa.dart");

#import('compiler_helper.dart');
#import('parser_helper.dart');

void compileAndFind(String code,
                    String functionName,
                    check(compiler, element)) {
  Uri uri = new Uri.fromComponents(scheme: 'source');
  var compiler = compilerFor(code, uri);
  compiler.runCompiler(uri);
  var fun = findElement(compiler, functionName);
  return check(compiler.backend, fun);
}

// The 'f' function has an 'if' to make it non-inlinable.
const String TEST_ONE = @"""
  f(p) { if (p == null) return p; return p; }
  main() { f("s"); }
""";

const String TEST_TWO = @"""
  f(p) { if (p == null) return p; return p; }
  main() { f(1); }
""";

const String TEST_THREE = @"""
  f(p) { if (p == null) return p; return p; }
  main() { f(1); f(2); }
""";

const String TEST_FOUR = @"""
  f(p) { if (p == null) return p; return p; }
  main() { f(1.1); }
""";

const String TEST_FIVE = @"""
  f(p) { if (p == null) return p; return p; }
  main() { f(1); f(2.2); }
""";

const String TEST_SIX = @"""
  f(p) { if (p == null) return p; return p; }
  main() { f(1.1); f(2); }
""";

const String TEST_SEVEN = @"""
  f(p) { if (p == null) return p; return p; }
  main() { f(1); f("s"); }
""";

const String TEST_EIGHT = @"""
  f(p1, p2) { if (p1 == null) return p1; return p2; }
  main() { f(1, 2); f(1, "s"); }
""";

const String TEST_NINE = @"""
  f(p1, p2) { if (p1 == null) return p1; return p2; }
  main() { f("s", 2); f(1, "s"); }
""";

const String TEST_TEN = @"""
  f(p) { if (p == null) return p; return p; }
  g(p) { if (p== null) return null; return p(1); }
  main() { f(1); g(f); }
""";

void runTest(String test, [List<HType> expectedTypes = null]) {
  compileAndFind(
    test,
    'f',
    (backend, x) {
      List<HType> types =
          backend.optimisticParameterTypes(x);
      if (expectedTypes != null) {
        Expect.listEquals(expectedTypes, types);
      } else {
        Expect.isTrue(types.allUnknown);
      }
  });
}

void test() {
  runTest(TEST_ONE, [HType.STRING]);
  runTest(TEST_TWO, [HType.INTEGER]);
  runTest(TEST_THREE, [HType.INTEGER]);
  runTest(TEST_FOUR, [HType.DOUBLE]);
  runTest(TEST_FIVE, [HType.NUMBER]);
  runTest(TEST_SIX, [HType.NUMBER]);
  runTest(TEST_SEVEN);
  runTest(TEST_EIGHT, [HType.INTEGER, HType.UNKNOWN]);
  runTest(TEST_NINE);
  runTest(TEST_TEN);
}

void main() {
  test();
}
