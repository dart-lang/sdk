// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:uri");

#import("../../../lib/compiler/implementation/js_backend/js_backend.dart");
#import("../../../lib/compiler/implementation/ssa/ssa.dart");
#import("../../../lib/compiler/implementation/scanner/scannerlib.dart");

#import('compiler_helper.dart');
#import('parser_helper.dart');

void compileAndFind(String code,
                    String className,
                    String memberName,
                    bool disableInlining,
                    check(compiler, element)) {
  Uri uri = new Uri.fromComponents(scheme: 'source');
  var compiler = compilerFor(code, uri);
  compiler.disableInlining = disableInlining;
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
  main() { new A().x(1.5); }
""";

const String TEST_5 = @"""
  class A {
    x(p) => p;
  }
  main() {
    new A().x(1);
    new A().x(1.5);
  }
""";

const String TEST_6 = r"""
  class A {
    x(p) => p;
  }
  main() {
    new A().x(1.5);
    new A().x(1);
  }
""";

const String TEST_7 = r"""
  class A {
    x(p) => x("x");
  }
  main() {
    new A().x(1);
  }
""";

const String TEST_8 = r"""
  class A {
    x(p1, p2) => x(p1, "x");
  }
  main() {
    new A().x(1, 2);
  }
""";

const String TEST_9 = r"""
  class A {
    x(p1, p2) => x(p1, p2);
  }
  main() {
    new A().x(1, 2);
  }
""";

const String TEST_10 = r"""
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

const String TEST_11 = r"""
  class A {
    x(p1, p2) => x(1, 2);
  }
  main() {
    new A().x("x", "y");
  }
""";

const String TEST_12 = r"""
  class A {
    x(p1, [p2 = 1]) => 1;
  }
  main() {
    new A().x("x", 1);
    new A().x("x");
  }
""";

const String TEST_13 = r"""
  class A {
    x(p) => 1;
  }
  f(p) => p.x(2.2);
  main() {
    new A().x(1);
    f(null);
  }
""";

const String TEST_14 = @"""
  class A {
    x(p1, [p2 = "s"]) => 1;
  }
  main() {
    new A().x(1);
  }
""";

const String TEST_15 = @"""
  class A {
    x(p1, [p2 = true]) => 1;
  }
  f(p) => p.a("x");
  main() {
    new A().x("x");
    new A().x("x", false);
    f(null);
  }
""";

const String TEST_16 = @"""
  class A {
    x(p1, [p2 = 1, p3 = "s"]) => 1;
  }
  main() {
    new A().x(1);
    new A().x(1, 2);
    new A().x(1, 2, "x");
    new A().x(1, p2: 2);
    new A().x(1, p3: "x");
    new A().x(1, p3: "x", p2: 2);
    new A().x(1, p2: 2, p3: "x");
  }
""";

const String TEST_17 = @"""
  class A {
    x(p1, [p2 = 1, p3 = "s"]) => 1;
  }
  main() {
    new A().x(1, true, 1.1);
    new A().x(1, false, 2.2);
    new A().x(1, p3: 3.3, p2: true);
    new A().x(1, p2: false, p3: 4.4);
  }
""";

void doTest(String test,
            bool enableInlining,
            List<HType> expectedTypes,
            OptionalParameterTypes defaultTypes) {
  compileAndFind(
    test,
    'A',
    'x',
    enableInlining,
    (backend, x) {
      HTypeList types = backend.optimisticParameterTypes(x, defaultTypes);
      if (expectedTypes != null) {
        Expect.isFalse(types.allUnknown);
        Expect.listEquals(expectedTypes, types.types);
      } else {
        Expect.isTrue(types.allUnknown);
      }
  });
}

void runTest(String test,
             [List<HType> expectedTypes,
              OptionalParameterTypes defaultTypes]) {
  doTest(test, false, expectedTypes, defaultTypes);
  doTest(test, true, expectedTypes, defaultTypes);
}

void test() {
  OptionalParameterTypes defaultTypes;

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

  defaultTypes = new OptionalParameterTypes(1);
  defaultTypes.update(0, const SourceString("p2"), HType.INTEGER);
  runTest(TEST_12, [HType.STRING, HType.INTEGER], defaultTypes);

  runTest(TEST_13, [HType.NUMBER]);

  defaultTypes = new OptionalParameterTypes(1);
  defaultTypes.update(0, const SourceString("p2"), HType.STRING);
  runTest(TEST_14, [HType.INTEGER, HType.STRING], defaultTypes);

  defaultTypes = new OptionalParameterTypes(1);
  defaultTypes.update(0, const SourceString("p2"), HType.BOOLEAN);
  runTest(TEST_15, [HType.STRING, HType.BOOLEAN], defaultTypes);

  defaultTypes = new OptionalParameterTypes(2);
  defaultTypes.update(0, const SourceString("p2"), HType.INTEGER);
  defaultTypes.update(1, const SourceString("p3"), HType.STRING);
  runTest(TEST_16, [HType.INTEGER, HType.INTEGER, HType.STRING], defaultTypes);

  defaultTypes = new OptionalParameterTypes(2);
  defaultTypes.update(0, const SourceString("p2"), HType.INTEGER);
  defaultTypes.update(1, const SourceString("p3"), HType.STRING);
  runTest(TEST_17, [HType.INTEGER, HType.BOOLEAN, HType.DOUBLE], defaultTypes);
}

void main() {
  test();
}
