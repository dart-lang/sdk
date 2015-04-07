// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test code
import 'dart:collection';
import 'dart:mirrors';
import 'package:unittest/unittest.dart';
import 'package:dev_compiler/config.dart';
import 'package:dev_compiler/runtime/dart_runtime.dart';

final bool intIsNonNullable = TypeOptions.NONNULLABLE_TYPES.contains('int');
final bool doubleIsNonNullable = TypeOptions.NONNULLABLE_TYPES.contains('double');

class A {
  int x;
}

class B extends A {
  int y;
}

class C extends B {
  int z;
}

class AA<T, U> {
  T x;
  U y;
}

class BB<T, U> extends AA<U, T> {
  T z;
}

class CC extends BB<String, List> {}

typedef Func2(x, y);
typedef B Foo(B b, String s);

A bar1(C c, String s) => null;
bar2(B b, String s) => null;
B bar3(B b, Object o) => null;
B bar4(B b, o) => null;
C bar5(A a, Object o) => null;
B bar6(B b, String s, String o) => null;
B bar7(B b, String s, [Object o]) => null;
B bar8(B b, String s, {Object p}) => null;

class Bar {
  B call(B b, String s) => null;
}

class Baz {
  Foo call = (B b, String s) => null;
}

class Checker<T> {
  void isGround(bool expected) => expect(isGroundType(T), equals(expected));
  void isGroundList(bool expected) => expect(isGroundType(new List<T>().runtimeType), equals(expected));
  void check(x, bool expected) => checkType(x, T, expected);
  void checkList(x, bool expected) => checkType(x, type((List<T> _) {}), expected);
}

bool dartIs(expr, Type type) {
  var exprMirror = reflectType(expr.runtimeType);
  var typeMirror = reflectType(type);
  return exprMirror.isSubtypeOf(typeMirror);
}

void checkType(x, Type type, [bool expectedTrue = true]) {
  var isGround = isGroundType(type);
  var restrictedSubType = instanceOf(x, type);
  var dartSubType = dartIs(x, type);

  // Matches expectation
  expect(restrictedSubType, equals(expectedTrue));

  // x is_R T => x is T
  expect(!restrictedSubType || dartSubType, isTrue);

  // x is T && isGroundType(T) => x is_R T
  expect(!(dartSubType && isGround) || restrictedSubType, isTrue);
}

void checkArity(Function f, int min, int max) {
  Arity arity = getArity(f);
  expect(arity.min, equals(min));
  expect(arity.max, equals(max));
}

void main() {
  test('int', () {
    expect(isGroundType(int), isTrue);
    expect(isGroundType(5.runtimeType), isTrue);

    checkType(5, int);
    checkType(5, dynamic);
    checkType(5, Object);
    checkType(5, num);

    checkType(5, bool, false);
    checkType(5, String, false);

    expect(cast(5, int), equals(5));
    if (intIsNonNullable) {
      expect(() => cast(null, int), throws);
    } else {
      expect(cast(null, int), equals(null));
    }
  });

  test('dynamic', () {
    expect(isGroundType(dynamic), isTrue);
    checkType(new Object(), dynamic);
    checkType(null, dynamic);

    expect(cast(null, dynamic), equals(null));
  });

  test('Object', () {
    expect(isGroundType(Object), isTrue);
    checkType(new Object(), dynamic);
    checkType(null, Object);

    expect(cast(null, Object), equals(null));
  });

  test('String', () {
    expect(isGroundType(String), isTrue);
    expect(isGroundType("foo".runtimeType), isTrue);
    checkType("foo", String);
    checkType("foo", Object);
    checkType("foo", dynamic);

    expect(cast(null, String), equals(null));
  });

  test('Map', () {
    final m1 = new Map<String, String>();
    final m2 = new Map<Object, Object>();
    final m3 = new Map();
    final m4 = new HashMap<dynamic, dynamic>();
    final m5 = new LinkedHashMap();

    expect(isGroundType(Map), isTrue);
    expect(isGroundType(m1.runtimeType), isFalse);
    expect(isGroundType(type((Map<String, String> _) {})), isFalse);
    expect(isGroundType(m2.runtimeType), isTrue);
    expect(isGroundType(type((Map<Object, Object> _) {})), isTrue);
    expect(isGroundType(m3.runtimeType), isTrue);
    expect(isGroundType(type((Map _) {})), isTrue);
    expect(isGroundType(m4.runtimeType), isTrue);
    expect(isGroundType(type((HashMap<dynamic, dynamic> _) {})), isTrue);
    expect(isGroundType(m5.runtimeType), isTrue);
    expect(isGroundType(type((LinkedHashMap _) {})), isTrue);
    expect(isGroundType(LinkedHashMap), isTrue);

    // Map<T1,T2> <: Map
    checkType(m1, Map);
    checkType(m1, Object);

    // Instance of self
    checkType(m1, m1.runtimeType);
    checkType(m1, type((Map<String, String> _) {}));

    // Object == dynamic == top as a type parameter
    checkType(m2, m3.runtimeType);
    checkType(m2, Map);
    checkType(m3, m2.runtimeType);
    checkType(m3, type((Map<Object, Object> _) {}));

    // Covariance on generics
    checkType(m1, m2.runtimeType);
    checkType(m1, type((Map<Object, Object> _) {}));

    // No contravariance on generics.
    checkType(m2, m1.runtimeType, false);
    checkType(m2, type((Map<String, String> _) {}), false);

    // null is! Map
    checkType(null, Map, false);

    // Raw generic types
    checkType(m5, Map);
    checkType(m5, type((Map<Object, Object> _) {}));
    checkType(m4, Map);
    checkType(m4, type((Map<Object, Object> _) {}));

    // Mixin: the actual implementation class should implement MapMixin
    checkType(m1, MapMixin);
    checkType(m1, type((MapMixin<String, String> _) {}));
    checkType(m1, type((MapMixin<Object, Object> _) {}));
    checkType(m5, MapMixin);
    checkType(m5, type((MapMixin<String, String> _) {}), false);
    checkType(m5, type((MapMixin<Object, Object> _) {}));
  });

  test('generic and inheritance', () {
    AA aaraw = new AA();
    final aarawtype = aaraw.runtimeType;
    AA<dynamic, dynamic> aadynamic = new AA<dynamic, dynamic>();
    final aadynamictype = aadynamic.runtimeType;
    AA<String, List> aa = new AA<String, List>();
    final aatype = aa.runtimeType;
    BB<String, List> bb = new BB<String, List>();
    final bbtype = bb.runtimeType;
    CC cc = new CC();
    final cctype = cc.runtimeType;
    AA<String> aabad = new AA<String>();
    final aabadtype = aabad.runtimeType;

    expect(isGroundType(aatype), isFalse);
    expect(isGroundType(type((AA<String, List> _) {})), isFalse);
    expect(isGroundType(bbtype), isFalse);
    expect(isGroundType(type((BB<String, List> _) {})), isFalse);
    expect(isGroundType(cctype), isTrue);
    expect(isGroundType(CC), isTrue);
    checkType(cc, aatype, false);
    checkType(cc, type((AA<String, List> _) {}), false);
    checkType(cc, bbtype);
    checkType(cc, type((BB<String, List> _) {}));
    checkType(aa, cctype, false);
    checkType(aa, CC, false);
    checkType(aa, bbtype, false);
    checkType(aa, type((BB<String, List> _) {}), false);
    checkType(bb, cctype, false);
    checkType(bb, CC, false);
    checkType(aa, aabadtype);
    checkType(aa, type((AA<String> _) {}));
    checkType(aabad, aatype, false);
    checkType(aabad, type((AA<String, List> _) {}), false);
    checkType(aabad, aarawtype);
    checkType(aabad, AA);
    checkType(aaraw, aabadtype);
    checkType(aaraw, type((AA<String> _) {}));
    checkType(aaraw, aadynamictype);
    checkType(aaraw, type((AA<dynamic, dynamic> _) {}));
    checkType(aadynamic, aarawtype);
    checkType(aadynamic, AA);
  });

  test('Functions', () {
    // - return type: Dart is bivariant.  We're covariant.
    // - param types: Dart is bivariant.  We're contravariant.
    expect(isGroundType(Func2), isTrue);
    expect(isGroundType(Foo), isFalse);
    expect(isGroundType(type((B _(B _1, String _2)) {})), isFalse);
    checkType(bar1, Foo, false);
    checkType(bar1, type((B _(B _1, String _2)) {}), false);
    checkType(bar2, Foo, false);
    checkType(bar2, type((B _(B _1, String _2)) {}), false);
    checkType(bar3, Foo);
    checkType(bar3, type((B _(B _1, String _2)) {}));
    checkType(bar4, Foo, false);
    // TODO(vsm): Revisit.  bar4 is (B, *) -> B.  Perhaps it should be treated as top for a reified object.
    checkType(bar4, type((B _(B _1, String _2)) {}), false);
    checkType(bar5, Foo);
    checkType(bar5, type((B _(B _1, String _2)) {}));
    checkType(bar6, Foo, false);
    checkType(bar6, type((B _(B _1, String _2)) {}), false);
    checkType(bar7, Foo);
    checkType(bar7, type((B _(B _1, String _2)) {}));
    checkType(bar7, bar6.runtimeType);
    checkType(bar8, Foo);
    checkType(bar8, type((B _(B _1, String _2)) {}));
    checkType(bar8, bar6.runtimeType, false);
    checkType(bar7, bar8.runtimeType, false);
    checkType(bar8, bar7.runtimeType, false);
  });

  test('void', () {
    checkType((x) => x, type((void _(x)) {}));
  });

  test('null', () {
    checkType(null, Object);
    checkType(null, Null);
    checkType(null, dynamic);
    checkType(null, int, false);
    checkType(null, String, false);
    checkType(null, Map, false);

    expect(cast(null, Object), equals(null));
    expect(cast(null, String), equals(null));
    expect(cast(null, Map), equals(null));
  });

  test('Function objects', () {
    // Bar has a call method - it emulates the corresponding function.
    var bar = new Bar();
    checkType(bar, Bar);
    checkType(bar, Function);
    checkType(bar, Foo);
    checkType(bar, type((B _(B _1, String _2)) {}));
    checkType(bar, type((B _(String _1, String _2)) {}), false);

    // Baz has a call getter that is a closure - this does not make it a
    // function.
    var baz = new Baz();
    checkType(baz, Function, false);
    checkType(baz, Foo, false);
  });

  test('arity', () {
    checkArity(bar1, 2, 2);
    checkArity(bar4, 2, 2);
    checkArity(bar6, 3, 3);
    checkArity(bar7, 2, 3);
    checkArity(bar8, 2, 2);
    checkArity(() {}, 0, 0);
    checkArity((a, [b]) {}, 1, 2);
  });

  test('type variable', () {
    var stringChecker = new Checker<String>();
    stringChecker.isGround(true);
    stringChecker.isGroundList(false);

    stringChecker.check(5, false);
    stringChecker.check("hello", true);
    stringChecker.check(null, false);

    var objectChecker = new Checker<Object>();
    objectChecker.isGround(true);
    objectChecker.isGroundList(true);

    objectChecker.check(5, true);
    objectChecker.check("hello", true);
    objectChecker.check(null, true);
  });
}
