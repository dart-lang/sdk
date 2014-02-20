// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';
import 'parser_helper.dart';
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

main() {
  Uri uri = new Uri(scheme: 'source');

  checkReturn(MockCompiler compiler, String name, type) {
    var typesInferrer = compiler.typesTask.typesInferrer;
    var element = findElement(compiler, name);
    Expect.equals(
        type,
        simplify(typesInferrer.getReturnTypeOfElement(element), compiler),
        name);
  }

  var compiler1 = compilerFor(TEST1, uri);
  asyncTest(() => compiler1.runCompiler(uri).then((_) {
    checkReturn(compiler1, 'test1', compiler1.typesTask.uint31Type);
    checkReturn(compiler1, 'test2',
        compiler1.typesTask.dynamicType.nonNullable());
    checkReturn(compiler1, 'test3', compiler1.typesTask.uint31Type);
    checkReturn(compiler1, 'test4', compiler1.typesTask.mapType);
    checkReturn(compiler1, 'test5',
        compiler1.typesTask.dynamicType.nonNullable());
    checkReturn(compiler1, 'test6',
        compiler1.typesTask.dynamicType.nonNullable());
  }));

  var compiler2 = compilerFor(TEST2, uri);
  asyncTest(() => compiler2.runCompiler(uri).then((_) {
    checkReturn(compiler2, 'test1', compiler2.typesTask.mapType.nonNullable());
    checkReturn(compiler2, 'test2', compiler2.typesTask.mapType);
    checkReturn(compiler2, 'test3', compiler2.typesTask.mapType);
    checkReturn(compiler2, 'test4', compiler2.typesTask.mapType);
    checkReturn(compiler2, 'test5', compiler2.typesTask.mapType);

    checkReturn(compiler2, 'test6', compiler2.typesTask.numType);
    checkReturn(compiler2, 'test7', compiler2.typesTask.uint31Type);
    checkReturn(compiler2, 'test8', compiler2.typesTask.uint31Type);
    checkReturn(compiler2, 'test9', compiler2.typesTask.uint31Type);
    checkReturn(compiler2, 'test10', compiler2.typesTask.numType);
    checkReturn(compiler2, 'test11', compiler2.typesTask.doubleType);
  }));
}
