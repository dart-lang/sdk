// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:uri");

#import("../../../lib/compiler/implementation/ssa/ssa.dart");

#import('compiler_helper.dart');
#import('parser_helper.dart');

void compileAndFind(String code,
                    String className,
                    String memberName,
                    check(compiler, element)) {
  Uri uri = new Uri.fromComponents(scheme: 'source');
  var compiler = compilerFor(code, uri);
  compiler.runCompiler(uri);
  var cls = findElement(compiler, className);
  var member = cls.lookupLocalMember(buildSourceString(memberName));
  return check(compiler.backend, member);
}

const String TEST_ONE = @"""
  class A {
    x(p) => p;
  }
  main() { new A().x("s"); }
""";

const String TEST_TWO = @"""
  class A {
    x(p) => p;
  }
  main() { new A().x(1); }
""";

const String TEST_THREE = @"""
  class A {
    x(p) => x(p - 1);
  }
  main() { new A().x(1); }
""";

const String TEST_FOUR = @"""
  class A {
    x(p) => x(p - 1);
  }
  main() { new A().x(1.0); }
""";

const String TEST_FIVE = @"""
  class A {
    x(p) => p;
  }
  main() {
    new A().x(1);
    new A().x(1.0);
  }
""";

const String TEST_SIX = @"""
  class A {
    x(p) => p;
  }
  main() {
    new A().x(1.0);
    new A().x(1);
  }
""";

const String TEST_SEVEN = @"""
  class A {
    x(p) => x("x");
  }
  main() {
    new A().x(1);
  }
""";

const String TEST_EIGHT = @"""
  class A {
    x(p1, p2) => x(p1, "x");
  }
  main() {
    new A().x(1, 2);
  }
""";

const String TEST_NINE = @"""
  class A {
    x(p1, p2) => x(p1, p2);
  }
  main() {
    new A().x(1, 2);
  }
""";

const String TEST_TEN = @"""
  class A {
    x(p1, p2) => x(p1, p2);
  }
  void f(p) {
    p.x("x", "y");
  }
  main() {
    f(null);
    new A().x(1, 2);
  }
""";

const String TEST_ELEVEN = @"""
  class A {
    x(p1, p2) => x(1, 2);
  }
  main() {
    new A().x("x", "y");
  }
""";

const String TEST_TWELVE = @"""
  class A {
    x(p1, p2) => 1;
  }
  class B {
    x(p1, p2) => x(1, 2);
  }
  f(p) => p.x(1);
  main() {
    var x;
    new A().x("x", "y");
    f(x);
  }
""";

const String TEST_13 = @"""
  class A {
    x(p1, [p2 = 1]) => 1;
  }
  main() {
    new A().x("x", 1);
    new A().x("x");
  }
""";

void runTest(String test, [List<HType> expectedTypes = null]) {
  compileAndFind(
    test,
    'A',
    'x',
    (backend, x) {
      List<HType> types =
          backend.optimisticParameterTypesWithRecompilationOnTypeChange(x);
      if (expectedTypes != null) {
        Expect.listEquals(expectedTypes, types);
      } else {
        Expect.isNull(types);
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
  runTest(TEST_NINE, [HType.INTEGER, HType.INTEGER]);
  runTest(TEST_TEN);
  runTest(TEST_ELEVEN);
  runTest(TEST_TWELVE);
  runTest(TEST_13);
}

void main() {
  test();
}
