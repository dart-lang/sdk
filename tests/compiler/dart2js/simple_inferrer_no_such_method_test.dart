// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';
import 'package:compiler/src/types/types.dart';
import 'type_mask_test_helper.dart';

const String TEST1 = """
class A {
  noSuchMethod(im) => 42;
}

class B extends A {
  foo();
}

class C extends B {
  foo() => {};
}

var a = [new B(), new C()][0];
test1() => new A().foo();
test2() => a.foo();
test3() => new B().foo();
test4() => new C().foo();
test5() => (a ? new A() : new B()).foo();
test6() => (a ? new B() : new C()).foo();

main() {
  test1();
  test2();
  test3();
  test4();
  test5();
  test6();
}
""";

const String TEST2 = """
abstract class A {
  noSuchMethod(im) => 42;
}

class B extends A {
  foo() => {};
}

class C extends B {
  foo() => {};
}

class D implements A {
  foo() => {};
  noSuchMethod(im) => 42.5;
}

var a = [new B(), new C(), new D()][0];
test1() => a.foo();
test2() => new B().foo();
test3() => new C().foo();
test4() => (a ? new B() : new C()).foo();
test5() => (a ? new B() : new D()).foo();

// Can hit A.noSuchMethod, D.noSuchMethod and Object.noSuchMethod.
test6() => a.bar();

// Can hit A.noSuchMethod.
test7() => new B().bar();
test8() => new C().bar();
test9() => (a ? new B() : new C()).bar();

// Can hit A.noSuchMethod and D.noSuchMethod.
test10() => (a ? new B() : new D()).bar();

// Can hit D.noSuchMethod.
test11() => new D().bar();

main() {
  test1();
  test2();
  test3();
  test4();
  test5();
  test6();
  test7();
  test8();
  test9();
  test10();
  test11();
}
""";

const String TEST3 = """
class A {
  // We may ignore this for type inference because syntactically it always
  // throws an exception.
  noSuchMethod(im) => throw 'foo';
}

class B extends A {
  foo() => {};
}

class C extends B {
  foo() => {};
}

var a = [new B(), new C()][0];
test1() => new A().foo();
test2() => a.foo();
test3() => new B().foo();
test4() => new C().foo();
test5() => (a ? new A() : new B()).foo();
test6() => (a ? new B() : new C()).foo();

main() {
  test1();
  test2();
  test3();
  test4();
  test5();
  test6();
}
""";

const String TEST4 = """
class A {
  // We may ignore this for type inference because it forwards to a default
  // noSuchMethod implementation, which always throws an exception.
  noSuchMethod(im) => super.noSuchMethod(im);
}

class B extends A {
  foo() => {};
}

class C extends B {
  foo() => {};
}

var a = [new B(), new C()][0];
test1() => new A().foo();
test2() => a.foo();
test3() => new B().foo();
test4() => new C().foo();
test5() => (a ? new A() : new B()).foo();
test6() => (a ? new B() : new C()).foo();

main() {
  test1();
  test2();
  test3();
  test4();
  test5();
  test6();
}
""";

checkReturn(MockCompiler compiler, String name, type) {
  var typesInferrer = compiler.globalInference.typesInferrerInternal;
  var element = findElement(compiler, name);
  Expect.equals(
      type,
      simplify(typesInferrer.getReturnTypeOfMember(element),
          typesInferrer.closedWorld),
      name);
}

test1() async {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST1, uri);
  await compiler.run(uri);
  var closedWorld = compiler.resolutionWorldBuilder.closedWorldForTesting;
  checkReturn(compiler, 'test1', closedWorld.commonMasks.uint31Type);
  checkReturn(
      compiler, 'test2', closedWorld.commonMasks.dynamicType.nonNullable());
  checkReturn(compiler, 'test3', closedWorld.commonMasks.uint31Type);
  checkReturn(compiler, 'test4', closedWorld.commonMasks.mapType);
  checkReturn(
      compiler, 'test5', closedWorld.commonMasks.dynamicType.nonNullable());
  checkReturn(
      compiler, 'test6', closedWorld.commonMasks.dynamicType.nonNullable());
}

test2() async {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST2, uri);
  await compiler.run(uri);
  var closedWorld = compiler.resolutionWorldBuilder.closedWorldForTesting;
  checkReturn(compiler, 'test1', closedWorld.commonMasks.mapType.nonNullable());
  checkReturn(compiler, 'test2', closedWorld.commonMasks.mapType);
  checkReturn(compiler, 'test3', closedWorld.commonMasks.mapType);
  checkReturn(compiler, 'test4', closedWorld.commonMasks.mapType);
  checkReturn(compiler, 'test5', closedWorld.commonMasks.mapType);

  checkReturn(compiler, 'test6', closedWorld.commonMasks.numType);
  checkReturn(compiler, 'test7', closedWorld.commonMasks.uint31Type);
  checkReturn(compiler, 'test8', closedWorld.commonMasks.uint31Type);
  checkReturn(compiler, 'test9', closedWorld.commonMasks.uint31Type);
  checkReturn(compiler, 'test10', closedWorld.commonMasks.numType);
  checkReturn(compiler, 'test11', closedWorld.commonMasks.doubleType);
}

test3() async {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST3, uri);
  await compiler.run(uri);
  var closedWorld = compiler.resolutionWorldBuilder.closedWorldForTesting;
  checkReturn(compiler, 'test1', const TypeMask.nonNullEmpty());
  checkReturn(compiler, 'test2', closedWorld.commonMasks.mapType);
  checkReturn(compiler, 'test3', closedWorld.commonMasks.mapType);
  checkReturn(compiler, 'test4', closedWorld.commonMasks.mapType);
  checkReturn(compiler, 'test5', closedWorld.commonMasks.mapType);
  checkReturn(compiler, 'test6', closedWorld.commonMasks.mapType);
}

test4() async {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST4, uri);
  await compiler.run(uri);
  var closedWorld = compiler.resolutionWorldBuilder.closedWorldForTesting;
  checkReturn(compiler, 'test1', const TypeMask.nonNullEmpty());
  checkReturn(compiler, 'test2', closedWorld.commonMasks.mapType);
  checkReturn(compiler, 'test3', closedWorld.commonMasks.mapType);
  checkReturn(compiler, 'test4', closedWorld.commonMasks.mapType);
  checkReturn(compiler, 'test5', closedWorld.commonMasks.mapType);
  checkReturn(compiler, 'test6', closedWorld.commonMasks.mapType);
}

main() {
  asyncTest(() async {
    await test1();
    await test2();
    await test3();
    await test4();
  });
}
