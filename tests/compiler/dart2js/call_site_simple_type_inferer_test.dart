// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/types/masks.dart';
import 'package:expect/expect.dart';

import 'compiler_helper.dart';
import 'type_mask_test_helper.dart';

void compileAndFind(String code, String className, String memberName,
    bool disableInlining, check(compiler, element)) {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(code, uri, disableInlining: disableInlining);
  asyncTest(() => compiler.run(uri).then((_) {
        ClassElement cls = findElement(compiler, className);
        var member = cls.lookupLocalMember(memberName);
        return check(compiler, member);
      }));
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

typedef List<TypeMask> TestCallback(CommonMasks masks);

void doTest(String test, bool enableInlining, TestCallback f) {
  compileAndFind(test, 'A', 'x', enableInlining, (compiler, element) {
    var inferrer = compiler.globalInference.typesInferrerInternal;
    var closedWorld = inferrer.closedWorld;
    var expectedTypes = f(closedWorld.commonMasks);
    var signature = element.functionSignature;
    int index = 0;
    signature.forEachParameter((Element element) {
      Expect.equals(expectedTypes[index++],
          simplify(inferrer.getTypeOfElement(element), closedWorld), test);
    });
    Expect.equals(index, expectedTypes.length);
  });
}

void runTest(String test, TestCallback f) {
  doTest(test, false, f);
  doTest(test, true, f);
}

void test() {
  runTest(TEST_1, (commonMasks) => [commonMasks.stringType]);
  runTest(TEST_2, (commonMasks) => [commonMasks.uint31Type]);
  runTest(TEST_3, (commonMasks) => [commonMasks.intType]);
  runTest(TEST_4, (commonMasks) => [commonMasks.numType]);
  runTest(TEST_5, (commonMasks) => [commonMasks.numType]);
  runTest(TEST_6, (commonMasks) => [commonMasks.numType]);
  runTest(TEST_7a, (commonMasks) => [commonMasks.interceptorType]);
  runTest(TEST_7b, (commonMasks) => [commonMasks.dynamicType.nonNullable()]);

  runTest(
      TEST_8,
      (commonMasks) => [
            commonMasks.uint31Type,
            commonMasks.interceptorType,
            commonMasks.dynamicType.nonNullable()
          ]);
  runTest(TEST_9,
      (commonMasks) => [commonMasks.uint31Type, commonMasks.uint31Type]);
  runTest(TEST_10,
      (commonMasks) => [commonMasks.uint31Type, commonMasks.uint31Type]);
  runTest(
      TEST_11,
      (commonMasks) =>
          [commonMasks.interceptorType, commonMasks.interceptorType]);

  runTest(TEST_12,
      (commonMasks) => [commonMasks.stringType, commonMasks.uint31Type]);

  runTest(TEST_13, (commonMasks) => [commonMasks.numType]);

  runTest(TEST_14,
      (commonMasks) => [commonMasks.uint31Type, commonMasks.stringType]);

  runTest(
      TEST_15, (commonMasks) => [commonMasks.stringType, commonMasks.boolType]);

  runTest(
      TEST_16,
      (commonMasks) => [
            commonMasks.uint31Type,
            commonMasks.uint31Type,
            commonMasks.stringType
          ]);

  runTest(
      TEST_17,
      (commonMasks) => [
            commonMasks.uint31Type,
            commonMasks.boolType,
            commonMasks.doubleType
          ]);

  runTest(
      TEST_18,
      (commonMasks) =>
          [commonMasks.interceptorType, commonMasks.interceptorType]);
}

void main() {
  test();
}
