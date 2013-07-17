// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'compiler_helper.dart';
import 'parser_helper.dart';

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

var a;
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

var a;
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

main() {
  Uri uri = new Uri(scheme: 'source');

  var compiler = compilerFor(TEST1, uri);
  compiler.runCompiler(uri);
  var typesInferrer = compiler.typesTask.typesInferrer;

  checkReturn(String name, type) {
    var element = findElement(compiler, name);
    Expect.equals(
        type,
        typesInferrer.getReturnTypeOfElement(element).simplify(compiler),
        name);
  }

  checkReturn('test1', compiler.typesTask.intType);
  checkReturn('test2', compiler.typesTask.dynamicType.nonNullable());
  checkReturn('test3', compiler.typesTask.intType);
  checkReturn('test4', compiler.typesTask.mapType);
  checkReturn('test5', compiler.typesTask.dynamicType.nonNullable());
  checkReturn('test6', compiler.typesTask.dynamicType.nonNullable());

  compiler = compilerFor(TEST2, uri);
  compiler.runCompiler(uri);
  typesInferrer = compiler.typesTask.typesInferrer;

  checkReturn('test1', compiler.typesTask.dynamicType.nonNullable());
  checkReturn('test2', compiler.typesTask.mapType);
  checkReturn('test3', compiler.typesTask.mapType);
  checkReturn('test4', compiler.typesTask.mapType);
  checkReturn('test5', compiler.typesTask.mapType);

  checkReturn('test6', compiler.typesTask.numType);
  checkReturn('test7', compiler.typesTask.intType);
  checkReturn('test8', compiler.typesTask.intType);
  checkReturn('test9', compiler.typesTask.intType);
  checkReturn('test10', compiler.typesTask.numType);
  checkReturn('test11', compiler.typesTask.doubleType);
}
