// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/types/types.dart' show TypeMask;
import 'package:compiler/src/world.dart' show ClosedWorld;

import 'compiler_helper.dart';
import 'type_mask_test_helper.dart';

void compileAndFind(String code, String className, String memberName,
    bool disableInlining, check(compiler, element)) {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(code, uri, disableInlining: disableInlining);
  asyncTest(() => compiler.run(uri).then((_) {
        dynamic cls = findElement(compiler, className);
        var member = cls.lookupMember(memberName);
        check(compiler, member);
      }));
}

const String TEST_1 = r"""
  class A {
    int f;
  }
  main() { new A(); }
""";

const String TEST_2 = r"""
  class A {
    int f1;
    int f2 = 1;
  }
  main() { new A(); }
""";

const String TEST_3 = r"""
  class A {
    int f1;
    int f2;
    A() : f1 = 1;
  }
  main() { new A().f2 = 2; }
""";

const String TEST_4 = r"""
  class A {
    int f1;
    int f2;
    A() : f1 = 1;
  }
  main() {
    A a = new A();
    a.f1 = "a";
    a.f2 = "a";
  }
""";

const String TEST_5 = r"""
  class A {
    int f1 = 1;
    int f2 = 1;
    A(x) {
      f1 = "1";
      if (x) {
        f2 = "1";
      } else {
        f2 = "2";
      }
    }
  }
  main() {
    new A(true);
    new A(false);
  }
""";

const String TEST_6 = r"""
  class A {
    int f1 = 1;
    int f2 = 1;
    A(x) {
      f1 = "1";
      if (x) {
        f2 = "1";
      } else {
        f2 = "2";
      }
      if (x) {
        f2 = new List();
      } else {
        f2 = new List();
      }
    }
  }
  main() {
    new A(true);
    new A(false);
  }
""";

const String TEST_7 = r"""
  class A {
    int f1 = 1;
    int f2 = 1;
    A(x) {
      f1 = "1";
      if (x) {
        f2 = "1";
      } else {
        f2 = "2";
      }
      if (x) {
        f1 = new List();
        f2 = new List();
      } else {
        f2 = new List();
      }
    }
  }
  main() {
    new A(true);
    new A(false);
  }
""";

const String TEST_8 = r"""
  class A {
    int f;
    A(x) {
      if (x) {
        f = "1";
      } else {
      }
    }
  }
  main() {
    new A(true);
    new A(false);
  }
""";

const String TEST_9 = r"""
  class A {
    int f;
    A(x) {
      if (x) {
      } else {
        f = "1";
      }
    }
  }
  main() {
    new A(true);
    new A(false);
  }
""";

const String TEST_10 = r"""
  class A {
    int f;
    A() {
      f = 1;
    }
    m() => f + 1;
  }
  void f(x) { x.f = "2"; }
  main() {
    A a;
    f(a);
    a = new A();
    a.m();
  }
""";

const String TEST_11 = r"""
  class S {
    int fs = 1;
    ms() { fs = 1; }
  }

  class A extends S {
    m() { ms(); }
  }

  main() {
    A a = new A();
    a.m();
  }
""";

const String TEST_12 = r"""
  class S {
    int fs = 1;
    S() { fs = "2"; }
  }

  class A extends S {
  }

  main() {
    A a = new A();
  }
""";

const String TEST_13 = r"""
  class S {
    int fs;
    S() { fs = 1; }
  }

  class A extends S {
    A() { fs = 1; }
  }

  main() {
    A a = new A();
  }
""";

const String TEST_14 = r"""
  class A {
    var f;
    A() { f = 1; }
    A.other() { f = 2; }
  }

  main() {
    A a = new A();
    a = new A.other();
  }
""";

const String TEST_15 = r"""
  class A {
    var f;
    A() { f = "1"; }
    A.other() { f = new List(); }
  }

  main() {
    A a = new A();
    a = new A.other();
  }
""";

const String TEST_16 = r"""
  class A {
    var f;
    A() { f = "1"; }
    A.other() : f = 1 { }
  }

  main() {
    A a = new A();
    a = new A.other();
  }
""";

const String TEST_17 = r"""
  g([p]) => p.f = 1;
  class A {
    var f;
    A(x) {
      var a;
      if (x) {
        a = this;
      } else {
        a = g;
      }
      a(this);
    }
  }
  main() {
    new A(true);
    new A(false);
  }
""";

const String TEST_18 = r"""
  class A {
    var f1;
    var f2;
    var f3;
    A(x) {
      f1 = 1;
      var a;
      if (x) {
        f2 = "1";
        a = this;
      } else {
        a = 1;
        f2 = "1";
      }
      f3 = a;
    }
  }
  main() {
    new A(true);
    new A(false);
  }
""";

const String TEST_19 = r"""
  class A {
    var f1;
    var f2;
    var f3;
    A(x) {
      f1 = 1;
      var a;
      if (x) {
        f2 = "1";
        a = this;
      } else {
        a = 1;
        f2 = "1";
      }
      f3 = a;
      a();
    }
  }
  main() {
    new A(true);
    new A(false);
  }
""";

const String TEST_20 = r"""
  class A {
    var f;
    A() {
      for (f in this) {
      }
    }
    get iterator => this;
    get current => 42;
    bool moveNext() => false;
  }
  main() {
    new A();
  }
""";

const String TEST_21 = r"""
  class A {
    var f;
    A() {
      for (var i in this) {
      }
      f = 42;
    }
    get iterator => null;
  }
  main() {
    new A();
  }
""";

const String TEST_22 = r"""
  class A {
    var f1;
    var f2;
    var f3;
    A() {
      f1 = 42;
      f2 = f1 == null ? 42 : f3 == null ? 41: 43;
      f3 = 'foo';
    }
  }
  main() {
    new A();
  }
""";

const String TEST_23 = r"""
  class A {
    var f1 = 42;
    var f2 = 42;
    var f3 = 42;
    var f4 = 42;
    A() {
      // Test string interpolation.
      '${f1 = null}';
      // Test string juxtaposition.
      ''
      '${f2 = null}';
      // Test list literal.
      [f3 = null];
      // Test map literal.
      var c = {'foo': f4 = null };
    }
  }
  main() {
    new A();
  }
""";

const String TEST_24 = r"""
  class A {
    var f1 = 42;
    var f2 = 42;
    var f3 = 42;
    final f4;
    var f5;
    var f6 = null;
    A() : f4 = 42 {
      f1++;
      f2 += 42;
      var f6 = 'foo';
      this.f6 = f6;
    }
    A.foo(other) : f3 = other.f3, f4 = other.f4, f5 = other.bar();
    operator+(other) => 'foo';
    bar() => 42.5;
  }
  class B extends A {
    bar() => 42;
  }
  main() {
    new A();
    new A.foo(new A());
    new A.foo(new B());

  }
""";

const String TEST_25 = r"""
  class A {
    var f1 = 42;
  }
  class B {
    var f1 = '42';
  }
  main() {
    new B();
    new A().f1 = new A().f1;
  }
""";

const String TEST_26 = r"""
  class A {
    var f1 = 42;
  }
  class B {
    var f1 = 54;
  }
  main() {
    new A().f1 = [new B(), new A()][0].f1 + 42;
  }
""";

const String TEST_27 = r"""
  class A {
    var f1;
    var f2;
    A() {
      this.f1 = 42;
      this.f2 = 42;
    }
  }
  class B extends A {
    set f2(value) {}
  }
  main() {
    new A();
    new B();
  }
""";

const String TEST_28 = r"""
  class A {
    var f1;
    var f2;
    A(x) {
      this.f1 = x;
      if (x == 0) return;
      this.f2 = x;
    }
  }
  main() {
    new A(0);
    new A(1);
  }
""";

const String TEST_29 = r"""
  class A {
    var f1;
    var f2;
    A(x) {
      this.f1 = x;
      if (x == 0) {
      } else {
        return;
      }
      this.f2 = x;
    }
  }
  main() {
    new A(0);
    new A(1);
  }
""";

const String TEST_30 = r"""
  class A {
    var f1;
    var f2;
    var f3;
    A(x) {
      this.f1 = x;
      if (x == 0) {
        this.f2 = 1;
      } else {
        this.f2 = x;
        return;
      }
      this.f3 = x;
    }
  }
  main() {
    new A(0);
    new A(1);
  }
""";

typedef TypeMask TestCallback(ClosedWorld closedWorld);

void doTest(
    String test, bool disableInlining, Map<String, TestCallback> fields) {
  fields.forEach((String name, TestCallback f) {
    compileAndFind(test, 'A', name, disableInlining, (compiler, field) {
      var inferrer = compiler.globalInference.typesInferrerInternal;
      var closedWorld = inferrer.closedWorld;
      TypeMask type = f(closedWorld);
      TypeMask inferredType =
          simplify(inferrer.getTypeOfMember(field), closedWorld);
      Expect.equals(type, inferredType, '$name of:\n$test');
    });
  });
}

void runTest(String test, Map<String, TestCallback> fields) {
  doTest(test, false, fields);
  doTest(test, true, fields);
}

void test() {
  runTest(TEST_1, <String, TestCallback>{
    'f': (closedWorld) => closedWorld.commonMasks.nullType
  });
  runTest(TEST_2, <String, TestCallback>{
    'f1': (closedWorld) => closedWorld.commonMasks.nullType,
    'f2': (closedWorld) => closedWorld.commonMasks.uint31Type
  });
  runTest(TEST_3, <String, TestCallback>{
    'f1': (closedWorld) => closedWorld.commonMasks.uint31Type,
    'f2': (closedWorld) => closedWorld.commonMasks.uint31Type.nullable()
  });
  runTest(TEST_4, <String, TestCallback>{
    'f1': (closedWorld) => closedWorld.commonMasks.interceptorType,
    'f2': (closedWorld) => closedWorld.commonMasks.stringType.nullable()
  });

  // TODO(ngeoffray): We should try to infer that the initialization
  // code at the declaration site of the fields does not matter.
  runTest(TEST_5, <String, TestCallback>{
    'f1': (closedWorld) => closedWorld.commonMasks.interceptorType,
    'f2': (closedWorld) => closedWorld.commonMasks.interceptorType,
  });
  runTest(TEST_6, <String, TestCallback>{
    'f1': (closedWorld) => closedWorld.commonMasks.interceptorType,
    'f2': (closedWorld) => closedWorld.commonMasks.interceptorType,
  });
  runTest(TEST_7, <String, TestCallback>{
    'f1': (closedWorld) => closedWorld.commonMasks.interceptorType,
    'f2': (closedWorld) => closedWorld.commonMasks.interceptorType,
  });

  runTest(TEST_8, <String, TestCallback>{
    'f': (closedWorld) => closedWorld.commonMasks.stringType.nullable()
  });
  runTest(TEST_9, <String, TestCallback>{
    'f': (closedWorld) => closedWorld.commonMasks.stringType.nullable()
  });
  runTest(TEST_10, <String, TestCallback>{
    'f': (closedWorld) => closedWorld.commonMasks.uint31Type
  });
  runTest(TEST_11, <String, TestCallback>{
    'fs': (closedWorld) => closedWorld.commonMasks.uint31Type
  });

  // TODO(ngeoffray): We should try to infer that the initialization
  // code at the declaration site of the fields does not matter.
  runTest(TEST_12, <String, TestCallback>{
    'fs': (closedWorld) => closedWorld.commonMasks.interceptorType
  });

  runTest(TEST_13, <String, TestCallback>{
    'fs': (closedWorld) => closedWorld.commonMasks.uint31Type
  });
  runTest(TEST_14, <String, TestCallback>{
    'f': (closedWorld) => closedWorld.commonMasks.uint31Type
  });
  runTest(TEST_15, <String, TestCallback>{
    'f': (closedWorld) {
      ClassElement cls = closedWorld.commonElements.jsIndexableClass;
      return new TypeMask.nonNullSubtype(cls, closedWorld);
    }
  });
  runTest(TEST_16, <String, TestCallback>{
    'f': (closedWorld) => closedWorld.commonMasks.interceptorType
  });
  runTest(TEST_17, <String, TestCallback>{
    'f': (closedWorld) => closedWorld.commonMasks.uint31Type.nullable()
  });
  runTest(TEST_18, <String, TestCallback>{
    'f1': (closedWorld) => closedWorld.commonMasks.uint31Type,
    'f2': (closedWorld) => closedWorld.commonMasks.stringType,
    'f3': (closedWorld) => closedWorld.commonMasks.dynamicType
  });
  runTest(TEST_19, <String, TestCallback>{
    'f1': (closedWorld) => closedWorld.commonMasks.uint31Type,
    'f2': (closedWorld) => closedWorld.commonMasks.stringType,
    'f3': (closedWorld) => closedWorld.commonMasks.dynamicType
  });
  runTest(TEST_20, <String, TestCallback>{
    'f': (closedWorld) => closedWorld.commonMasks.uint31Type.nullable()
  });
  runTest(TEST_21, <String, TestCallback>{
    'f': (closedWorld) => closedWorld.commonMasks.uint31Type.nullable()
  });

  runTest(TEST_22, <String, TestCallback>{
    'f1': (closedWorld) => closedWorld.commonMasks.uint31Type,
    'f2': (closedWorld) => closedWorld.commonMasks.uint31Type,
    'f3': (closedWorld) => closedWorld.commonMasks.stringType.nullable()
  });

  runTest(TEST_23, <String, TestCallback>{
    'f1': (closedWorld) => closedWorld.commonMasks.uint31Type.nullable(),
    'f2': (closedWorld) => closedWorld.commonMasks.uint31Type.nullable(),
    'f3': (closedWorld) => closedWorld.commonMasks.uint31Type.nullable(),
    'f4': (closedWorld) => closedWorld.commonMasks.uint31Type.nullable()
  });

  runTest(TEST_24, <String, TestCallback>{
    'f1': (closedWorld) => closedWorld.commonMasks.positiveIntType,
    'f2': (closedWorld) => closedWorld.commonMasks.positiveIntType,
    'f3': (closedWorld) => closedWorld.commonMasks.uint31Type,
    'f4': (closedWorld) => closedWorld.commonMasks.uint31Type,
    'f5': (closedWorld) => closedWorld.commonMasks.numType.nullable(),
    'f6': (closedWorld) => closedWorld.commonMasks.stringType.nullable()
  });

  runTest(TEST_25, <String, TestCallback>{
    'f1': (closedWorld) => closedWorld.commonMasks.uint31Type
  });
  runTest(TEST_26, <String, TestCallback>{
    'f1': (closedWorld) => closedWorld.commonMasks.positiveIntType
  });
  runTest(TEST_27, <String, TestCallback>{
    'f1': (closedWorld) => closedWorld.commonMasks.uint31Type,
    'f2': (closedWorld) => closedWorld.commonMasks.uint31Type.nullable()
  });
  runTest(TEST_28, <String, TestCallback>{
    'f1': (closedWorld) => closedWorld.commonMasks.uint31Type,
    'f2': (closedWorld) => closedWorld.commonMasks.uint31Type.nullable()
  });
  runTest(TEST_29, <String, TestCallback>{
    'f1': (closedWorld) => closedWorld.commonMasks.uint31Type,
    'f2': (closedWorld) => closedWorld.commonMasks.uint31Type.nullable()
  });
  runTest(TEST_30, <String, TestCallback>{
    'f1': (closedWorld) => closedWorld.commonMasks.uint31Type,
    'f2': (closedWorld) => closedWorld.commonMasks.uint31Type,
    'f3': (closedWorld) => closedWorld.commonMasks.uint31Type.nullable()
  });
}

void main() {
  test();
}
