// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import '../../../sdk/lib/_internal/compiler/implementation/types/types.dart'
    show TypeMask;

import 'compiler_helper.dart';
import 'parser_helper.dart';

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
  return check(compiler.typesTask.typesInferrer, member);
}

const String TEST_1 = r"""
  class A {
    x(p) => p;
  }
  main() { new A().x("s"); }
""";

const String TEST_2 = r"""
  class A {
    x(p) => p;
  }
  main() { new A().x(1); }
""";

const String TEST_3 = r"""
  class A {
    x(p) => x(p - 1);
  }
  main() { new A().x(1); }
""";

const String TEST_4 = r"""
  class A {
    x(p) => x(p - 1);
  }
  main() { new A().x(1.5); }
""";

const String TEST_5 = r"""
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

const String TEST_7a = r"""
  class A {
    x(p) => x("x");
  }
  main() {
    new A().x(1);
  }
""";

const String TEST_7b = r"""
  class A {
    x(p) => x("x");
  }
  main() {
    new A().x({});
  }
""";

const String TEST_8 = r"""
  class A {
    x(p1, p2, p3) => x(p1, "x", {});
  }
  main() {
    new A().x(1, 2, 3);
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
    f(new A());
  }
""";

const String TEST_14 = r"""
  class A {
    x(p1, [p2 = "s"]) => 1;
  }
  main() {
    new A().x(1);
  }
""";

const String TEST_15 = r"""
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

const String TEST_16 = r"""
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

const String TEST_17 = r"""
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

const String TEST_18 = r"""
  class A {
    x(p1, p2) => x(p1, p2);
  }
  class B extends A {
  }
  main() {
    new B().x("a", "b");
    new A().x(1, 2);
  }
""";

void doTest(String test, bool enableInlining, Function f) {
  compileAndFind(
    test,
    'A',
    'x',
    enableInlining,
    (inferrer, element) {
      var expectedTypes = f(inferrer);
      var signature = element.computeSignature(inferrer.compiler);
      int index = 0;
      signature.forEachParameter((Element element) {
        Expect.equals(expectedTypes[index++], inferrer.typeOf[element]);
      });
      Expect.equals(index, expectedTypes.length);
  });
}

void runTest(String test, Function f) {
  doTest(test, false, f);
  doTest(test, true, f);
}

subclassOfInterceptor(inferrer) {
  return findTypeMask(inferrer.compiler, 'Interceptor', 'nonNullSubclass');
}

void test() {
  runTest(TEST_1, (inferrer) => [inferrer.stringType]);
  runTest(TEST_2, (inferrer) => [inferrer.intType]);
  runTest(TEST_3, (inferrer) => [inferrer.numType]);
  runTest(TEST_4, (inferrer) => [inferrer.numType]);
  runTest(TEST_5, (inferrer) => [inferrer.numType]);
  runTest(TEST_6, (inferrer) => [inferrer.numType]);
  runTest(TEST_7a, (inferrer) => [subclassOfInterceptor(inferrer)]);
  runTest(TEST_7b, (inferrer) => [inferrer.dynamicType]);

  // In the following tests, we can't infer the right types because we
  // have recursive calls with the same parameters. We should build a
  // constraint system for those, to find the types.
  runTest(TEST_8, (inferrer) => [inferrer.dynamicType,
                                 subclassOfInterceptor(inferrer),
                                 inferrer.dynamicType]);
  runTest(TEST_9, (inferrer) => [inferrer.dynamicType, inferrer.dynamicType]);
  runTest(TEST_10, (inferrer) => [inferrer.dynamicType, inferrer.dynamicType]);
  runTest(TEST_11, (inferrer) => [subclassOfInterceptor(inferrer),
                                  subclassOfInterceptor(inferrer)]);

  runTest(TEST_12, (inferrer) => [inferrer.stringType, inferrer.intType]);

  runTest(TEST_13, (inferrer) => [inferrer.numType]);

  runTest(TEST_14, (inferrer) => [inferrer.intType, inferrer.stringType]);

  runTest(TEST_15, (inferrer) => [inferrer.stringType, inferrer.boolType]);

  runTest(TEST_16, (inferrer) => [inferrer.intType,
                                  inferrer.intType,
                                  inferrer.stringType]);

  runTest(TEST_17, (inferrer) => [inferrer.intType,
                                  inferrer.boolType,
                                  inferrer.doubleType]);

  runTest(TEST_18, (inferrer) => [inferrer.dynamicType, inferrer.dynamicType]);
}

void main() {
  test();
}
