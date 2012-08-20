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

final String TEST_ONE = @"""
  f(p) => p;
  main() { f("s"); }
""";

final String TEST_TWO = @"""
  f(p) => p;
  main() { f(1); }
""";

final String TEST_THREE = @"""
  f(p) => p;
  main() { f(1); f(2); }
""";

final String TEST_FOUR = @"""
  f(p) => p;
  main() { f(1.1); }
""";

final String TEST_FIVE = @"""
  f(p) => p;
  main() { f(1); f(2.2); }
""";

final String TEST_SIX = @"""
  f(p) => p;
  main() { f(1.1); f(2); }
""";

final String TEST_SEVEN = @"""
  f(p) => p;
  main() { f(1); f("s"); }
""";

final String TEST_EIGHT = @"""
  f(p1, p2) => p1;
  main() { f(1, 2); f(1, "s"); }
""";

final String TEST_NINE = @"""
  f(p1, p2) => p1;
  main() { f("s", 2); f(1, "s"); }
""";

final String TEST_TEN = @"""
  f(p) => p;
  g(p) => p(1);
  main() { f(1); g(f); }
""";

void runTest(String test, [HType expectedType = HType.UNKNOWN]) {
  compileAndFind(
    test,
    'f',
    (backend, x) {
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
