// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:uri");

#import("../../../lib/compiler/implementation/ssa/ssa.dart");

#import('compiler_helper.dart');
#import('parser_helper.dart');

findElement(var compiler, String name) {
  var element = compiler.mainApp.find(buildSourceString(name));
  Expect.isNotNull(element, 'Could not locate $name.');
  return element;
}

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

final String TEST_ONE = @"""
  class A {
    x(p) => p;
  }
  main() { new A().x("s"); }
""";

final String TEST_TWO = @"""
  class A {
    x(p) => p;
  }
  main() { new A().x(1); }
""";

final String TEST_THREE = @"""
  class A {
    x(p) => x(p - 1);
  }
  main() { new A().x(1); }
""";

final String TEST_FOUR = @"""
  class A {
    x(p) => x(p - 1);
  }
  main() { new A().x(1.0); }
""";

final String TEST_FIVE = @"""
  class A {
    x(p) => p;
  }
  main() {
    new A().x(1);
    new A().x(1.0);
  }
""";

final String TEST_SIX = @"""
  class A {
    x(p) => p;
  }
  main() {
    new A().x(1.0);
    new A().x(1);
  }
""";

final String TEST_SEVEN = @"""
  class A {
    x(p) => x("x");
  }
  main() {
    new A().x(1);
  }
""";

final String TEST_EIGHT = @"""
  class A {
    x(p1, p2) => x(p1, "x");
  }
  main() {
    new A().x(1, 2);
  }
""";

final String TEST_NINE = @"""
  class A {
    x(p1, p2) => x(p1, p2);
  }
  void f(p) {
    p.x("x", "y");
  }
  main() {
    new A().x(1, 2);
  }
""";

final String TEST_TEN = @"""
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
  runTest(TEST_TEN);
}

void main() {
  test();
}
