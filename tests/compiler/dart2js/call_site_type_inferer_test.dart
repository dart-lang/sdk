// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:uri");

#import("../../../lib/compiler/implementation/js_backend/js_backend.dart");
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

const String TEST_1 = @"""
  class A {
    x(p) => p;
  }
  main() { new A().x("s"); }
""";

const String TEST_2 = @"""
  class A {
    x(p) => p;
  }
  main() { new A().x(1); }
""";

const String TEST_3 = @"""
  class A {
    x(p) => x(p - 1);
  }
  main() { new A().x(1); }
""";

const String TEST_4 = @"""
  class A {
    x(p) => x(p - 1);
  }
  main() { new A().x(1.0); }
""";

const String TEST_5 = @"""
  class A {
    x(p) => p;
  }
  main() {
    new A().x(1);
    new A().x(1.0);
  }
""";

const String TEST_6 = @"""
  class A {
    x(p) => p;
  }
  main() {
    new A().x(1.0);
    new A().x(1);
  }
""";

const String TEST_7 = @"""
  class A {
    x(p) => x("x");
  }
  main() {
    new A().x(1);
  }
""";

const String TEST_8 = @"""
  class A {
    x(p1, p2) => x(p1, "x");
  }
  main() {
    new A().x(1, 2);
  }
""";

const String TEST_9 = @"""
  class A {
    x(p1, p2) => x(p1, p2);
  }
  main() {
    new A().x(1, 2);
  }
""";

const String TEST_10 = @"""
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

const String TEST_11 = @"""
  class A {
    x(p1, p2) => x(1, 2);
  }
  main() {
    new A().x("x", "y");
  }
""";

const String TEST_12 = @"""
  class A {
    x(p1, [p2 = 1]) => 1;
  }
  main() {
    new A().x("x", 1);
    new A().x("x");
  }
""";

const String TEST_13 = @"""
  class A {
    x(p) => 1;
  }
  f(p) => p.x(2.2);
  main() {
    new A().x(1);
    f(null);
  }
""";

void runTest(String test, [List<HType> expectedTypes = null]) {
  compileAndFind(
    test,
    'A',
    'x',
    (backend, x) {
      HTypeList types = backend.optimisticParameterTypes(x);
      if (expectedTypes != null) {
        Expect.listEquals(expectedTypes, types.types);
      } else {
        Expect.isTrue(types.allUnknown);
      }
  });
}

void test() {
  runTest(TEST_1, [HType.STRING]);
  runTest(TEST_2, [HType.INTEGER]);
  runTest(TEST_3, [HType.INTEGER]);
  runTest(TEST_4, [HType.DOUBLE]);
  runTest(TEST_5, [HType.NUMBER]);
  runTest(TEST_6, [HType.NUMBER]);
  runTest(TEST_7);
  runTest(TEST_8, [HType.INTEGER, HType.UNKNOWN]);
  runTest(TEST_9, [HType.INTEGER, HType.INTEGER]);
  runTest(TEST_10);
  runTest(TEST_11);
  runTest(TEST_12);
  runTest(TEST_13, [HType.NUMBER]);
}

void main() {
  test();
}
