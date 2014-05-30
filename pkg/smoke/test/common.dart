// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Common test code that is run by 3 tests: mirrors_test.dart,
/// mirrors_used_test.dart, and static_test.dart.
library smoke.test.common;

import 'package:smoke/smoke.dart' as smoke;
import 'package:unittest/unittest.dart';

main() {
  test('read value', () {
    var a = new A();
    expect(smoke.read(a, #i), 42);
    expect(smoke.read(a, #j), 44);
    expect(smoke.read(a, #j2), 44);
  });

  test('write value', () {
    var a = new A();
    smoke.write(a, #i, 43);
    expect(a.i, 43);
    smoke.write(a, #j2, 46);
    expect(a.j, 46);
    expect(a.j2, 46);
    expect(smoke.read(a, #j), 46);
    expect(smoke.read(a, #j2), 46);
  });

  test('invoke', () {
    var a = new A();

    smoke.invoke(a, #inc0, []);
    expect(a.i, 43);
    expect(smoke.read(a, #i), 43);
    expect(() => smoke.invoke(a, #inc0, [2]), throws);
    expect(a.i, 43);
    expect(() => smoke.invoke(a, #inc0, [1, 2, 3]), throws);
    expect(a.i, 43);

    expect(() => smoke.invoke(a, #inc1, []), throws);
    expect(a.i, 43);
    smoke.invoke(a, #inc1, [4]);
    expect(a.i, 47);

    smoke.invoke(a, #inc2, []);
    expect(a.i, 37);
    smoke.invoke(a, #inc2, [4]);
    expect(a.i, 41);

    expect(() => smoke.invoke(a, #inc1, [4, 5]), throws);
    expect(a.i, 41);
  });

  test('static invoke', () {
    A.staticValue = 42;
    smoke.invoke(A, #staticInc, []);
    expect(A.staticValue, 43);
  });

  test('read and invoke function', () {
    var a = new A();
    expect(a.i, 42);
    var f = smoke.read(a, #inc1);
    f(4);
    expect(a.i, 46);
    Function.apply(f, [4]);
    expect(a.i, 50);
  });

  test('invoke with adjust', () {
    var a = new A();
    smoke.invoke(a, #inc0, [], adjust: true);
    expect(a.i, 43);
    smoke.invoke(a, #inc0, [2], adjust: true);
    expect(a.i, 44);
    smoke.invoke(a, #inc0, [1, 2, 3], adjust: true);
    expect(a.i, 45);

    smoke.invoke(a, #inc1, [], adjust: true); // treat as null (-10)
    expect(a.i, 35);
    smoke.invoke(a, #inc1, [4], adjust: true);
    expect(a.i, 39);

    smoke.invoke(a, #inc2, [], adjust: true); // default is null (-10)
    expect(a.i, 29);
    smoke.invoke(a, #inc2, [4, 5], adjust: true);
    expect(a.i, 33);
  });

  test('has getter', () {
    expect(smoke.hasGetter(A, #i), isTrue);
    expect(smoke.hasGetter(A, #j2), isTrue);
    expect(smoke.hasGetter(A, #inc2), isTrue);
    expect(smoke.hasGetter(B, #a), isTrue);
    expect(smoke.hasGetter(B, #i), isFalse);
    expect(smoke.hasGetter(B, #f), isTrue);
    expect(smoke.hasGetter(D, #i), isTrue);

    expect(smoke.hasGetter(E, #x), isFalse);
    expect(smoke.hasGetter(E, #y), isTrue);
    expect(smoke.hasGetter(E, #z), isFalse); // don't consider noSuchMethod
  });

  test('has setter', () {
    expect(smoke.hasSetter(A, #i), isTrue);
    expect(smoke.hasSetter(A, #j2), isTrue);
    expect(smoke.hasSetter(A, #inc2), isFalse);
    expect(smoke.hasSetter(B, #a), isTrue);
    expect(smoke.hasSetter(B, #i), isFalse);
    expect(smoke.hasSetter(B, #f), isFalse);
    expect(smoke.hasSetter(D, #i), isTrue);

    // TODO(sigmund): should we support declaring a setter with no getter?
    // expect(smoke.hasSetter(E, #x), isTrue);
    expect(smoke.hasSetter(E, #y), isFalse);
    expect(smoke.hasSetter(E, #z), isFalse); // don't consider noSuchMethod
  });

  test('no such method', () {
    expect(smoke.hasNoSuchMethod(A), isFalse);
    expect(smoke.hasNoSuchMethod(E), isTrue);
    expect(smoke.hasNoSuchMethod(E2), isTrue);
    expect(smoke.hasNoSuchMethod(int), isFalse);
  });

  test('has instance method', () {
    expect(smoke.hasInstanceMethod(A, #inc0), isTrue);
    expect(smoke.hasInstanceMethod(A, #inc3), isFalse);
    expect(smoke.hasInstanceMethod(C, #inc), isTrue);
    expect(smoke.hasInstanceMethod(D, #inc), isTrue);
    expect(smoke.hasInstanceMethod(D, #inc0), isTrue);
    expect(smoke.hasInstanceMethod(F, #staticMethod), isFalse);
    expect(smoke.hasInstanceMethod(F2, #staticMethod), isFalse);
  });

  test('has static method', () {
    expect(smoke.hasStaticMethod(A, #inc0), isFalse);
    expect(smoke.hasStaticMethod(C, #inc), isFalse);
    expect(smoke.hasStaticMethod(D, #inc), isFalse);
    expect(smoke.hasStaticMethod(D, #inc0), isFalse);
    expect(smoke.hasStaticMethod(F, #staticMethod), isTrue);
    expect(smoke.hasStaticMethod(F2, #staticMethod), isFalse);
  });

  test('get declaration', () {
    var d = smoke.getDeclaration(B, #a);
    expect(d.name, #a);
    expect(d.isField, isTrue);
    expect(d.isProperty, isFalse);
    expect(d.isMethod, isFalse);
    expect(d.isFinal, isFalse);
    expect(d.isStatic, isFalse);
    expect(d.annotations, []);
    expect(d.type, A);

    d = smoke.getDeclaration(B, #w);
    expect(d.name, #w);
    expect(d.isField, isFalse);
    expect(d.isProperty, isTrue);
    expect(d.isMethod, isFalse);
    expect(d.isFinal, isFalse);
    expect(d.isStatic, isFalse);
    expect(d.annotations, []);
    expect(d.type, int);

    d = smoke.getDeclaration(A, #inc1);
    expect(d.name, #inc1);
    expect(d.isField, isFalse);
    expect(d.isProperty, isFalse);
    expect(d.isMethod, isTrue);
    expect(d.isFinal, isFalse);
    expect(d.isStatic, isFalse);
    expect(d.annotations, []);
    expect(d.type, Function);

    d = smoke.getDeclaration(F, #staticMethod);
    expect(d.name, #staticMethod);
    expect(d.isField, isFalse);
    expect(d.isProperty, isFalse);
    expect(d.isMethod, isTrue);
    expect(d.isFinal, isFalse);
    expect(d.isStatic, isTrue);
    expect(d.annotations, []);
    expect(d.type, Function);

    d = smoke.getDeclaration(G, #b);
    expect(d.name, #b);
    expect(d.isField, isTrue);
    expect(d.isProperty, isFalse);
    expect(d.isMethod, isFalse);
    expect(d.isFinal, isFalse);
    expect(d.isStatic, isFalse);
    expect(d.annotations, [const Annot()]);
    expect(d.type, int);

    d = smoke.getDeclaration(G, #d);
    expect(d.name, #d);
    expect(d.isField, isTrue);
    expect(d.isProperty, isFalse);
    expect(d.isMethod, isFalse);
    expect(d.isFinal, isFalse);
    expect(d.isStatic, isFalse);
    expect(d.annotations, [32]);
    expect(d.type, int);
  });

  test('isSuperclass', () {
    expect(smoke.isSubclassOf(D, C), isTrue);
    expect(smoke.isSubclassOf(H, G), isTrue);
    expect(smoke.isSubclassOf(H, H), isTrue);
    expect(smoke.isSubclassOf(H, Object), isTrue);
    expect(smoke.isSubclassOf(B, Object), isTrue);
    expect(smoke.isSubclassOf(A, Object), isTrue);
    expect(smoke.isSubclassOf(AnnotB, Annot), isTrue);

    expect(smoke.isSubclassOf(D, A), isFalse);
    expect(smoke.isSubclassOf(H, B), isFalse);
    expect(smoke.isSubclassOf(B, A), isFalse);
    expect(smoke.isSubclassOf(Object, A), isFalse);
  });

  group('query', () {
    _checkQuery(result, names) {
      expect(result.map((e) => e.name), unorderedEquals(names));
    }

    test('default', () {
      var options = new smoke.QueryOptions();
      var res = smoke.query(A, options);
      _checkQuery(res, [#i, #j, #j2]);
    });

    test('only fields', () {
      var options = new smoke.QueryOptions(includeProperties: false);
      var res = smoke.query(A, options);
      _checkQuery(res, [#i, #j]);
    });

    test('only properties', () {
      var options = new smoke.QueryOptions(includeFields: false);
      var res = smoke.query(A, options);
      _checkQuery(res, [#j2]);
    });

    test('properties and methods', () {
      var options = new smoke.QueryOptions(includeMethods: true);
      var res = smoke.query(A, options);
      _checkQuery(res, [#i, #j, #j2, #inc0, #inc1, #inc2]);
    });

    test('inherited properties and fields', () {
      var options = new smoke.QueryOptions(includeInherited: true);
      var res = smoke.query(D, options);
      _checkQuery(res, [#x, #y, #b, #i, #j, #j2, #x2, #i2]);
    });

    test('inherited fields only', () {
      var options = new smoke.QueryOptions(includeInherited: true,
          includeProperties: false);
      var res = smoke.query(D, options);
      _checkQuery(res, [#x, #y, #b, #i, #j]);
    });

    test('exact annotation', () {
      var options = new smoke.QueryOptions(includeInherited: true,
          withAnnotations: const [a1]);
      var res = smoke.query(H, options);
      _checkQuery(res, [#b, #f, #g]);

      options = new smoke.QueryOptions(includeInherited: true,
          withAnnotations: const [a2]);
      res = smoke.query(H, options);
      _checkQuery(res, [#d, #h]);

      options = new smoke.QueryOptions(includeInherited: true,
          withAnnotations: const [a1, a2]);
      res = smoke.query(H, options);
      _checkQuery(res, [#b, #d, #f, #g, #h]);
    });

    test('type annotation', () {
      var options = new smoke.QueryOptions(includeInherited: true,
          withAnnotations: const [Annot]);
      var res = smoke.query(H, options);
      _checkQuery(res, [#b, #f, #g, #i]);
    });

    test('mixed annotations (type and exact)', () {
      var options = new smoke.QueryOptions(includeInherited: true,
          withAnnotations: const [a2, Annot]);
      var res = smoke.query(H, options);
      _checkQuery(res, [#b, #d, #f, #g, #h, #i]);
    });

    test('symbol to name', () {
      expect(smoke.symbolToName(#i), 'i');
    });

    test('name to symbol', () {
      expect(smoke.nameToSymbol('i'), #i);
    });
  });
}

class A {
  int i = 42;
  int j = 44;
  int get j2 => j;
  void set j2(int v) { j = v; }
  void inc0() { i++; }
  void inc1(int v) { i = i + (v == null ? -10 : v); }
  void inc2([int v]) { i = i + (v == null ? -10 : v); }

  static int staticValue = 42;
  static void staticInc() { staticValue++; }

}

class B {
  final int f = 3;
  int _w;
  int get w => _w;
  set w(int v) { _w = v; }

  String z;
  A a;

  B(this._w, this.z, this.a);
}

class C {
  int x;
  String y;
  B b;

  inc(int n) {
    x = x + n;
  }
  dec(int n) {
    x = x - n;
  }

  C(this.x, this.y, this.b);
}


class D extends C with A {
  int get x2 => x;
  int get i2 => i;

  D(x, y, b) : super(x, y, b);
}

class E {
  set x(int v) { }
  int get y => 1;

  noSuchMethod(i) => y;
}

class E2 extends E {}

class F {
  static int staticMethod(A a) => a.i;
}

class F2 extends F {}

class Annot { const Annot(); }
class AnnotB extends Annot { const AnnotB(); }
class AnnotC { const AnnotC({bool named: false}); }
const a1 = const Annot();
const a2 = 32;
const a3 = const AnnotB();


class G {
  int a;
  @a1 int b;
  int c;
  @a2 int d;
}

class H extends G {
  int e;
  @a1 int f;
  @a1 int g;
  @a2 int h;
  @a3 int i;
}

class K {
  @AnnotC(named: true) int k;
  @AnnotC() int k2;
}
