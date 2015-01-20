// Test code
import 'dart:collection';
import 'dart:mirrors';
import 'package:unittest/unittest.dart';
import 'package:ddc/runtime/dart_runtime.dart';

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

typedef B Foo(B b, String s);

A bar1(C c, String s) => null;
bar2(B b, String s) => null;
B bar3(B b, Object o) => null;
B bar4(B b, o) => null;
C bar5(A a, Object o) => null;
B bar6(B b, String s, String o) => null;
B bar7(B b, String s, [Object o]) => null;
B bar8(B b, String s, {Object p}) => null;

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
    expect(() => cast(null, int), throws);
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
    expect(isGroundType(m2.runtimeType), isFalse);
    expect(isGroundType(m3.runtimeType), isTrue);
    expect(isGroundType(m4.runtimeType), isTrue);
    expect(isGroundType(m5.runtimeType), isTrue);

    // Map<T1,T2> <: Map
    checkType(m1, Map);
    checkType(m1, Object);

    // Instance of self
    checkType(m1, m1.runtimeType);

    // Covariance on generics
    checkType(m1, m2.runtimeType);

    // No contravariance on generics.
    checkType(m2, m1.runtimeType, false);

    // null is! Map
    checkType(null, Map, false);

    // Raw generic types
    checkType(m5, Map);
    checkType(m4, Map);
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
    expect(isGroundType(bbtype), isFalse);
    expect(isGroundType(cctype), isTrue);
    checkType(cc, aatype, false);
    checkType(cc, bbtype);
    checkType(aa, cctype, false);
    checkType(aa, bbtype, false);
    checkType(bb, cctype, false);
    checkType(aa, aabadtype);
    checkType(aabad, aatype, false);
    checkType(aabad, aarawtype);
    checkType(aaraw, aabadtype);
    checkType(aaraw, aadynamictype);
    checkType(aadynamic, aarawtype);
  });

  test('Functions', () {
    // - return type: Dart is bivariant.  We're covariant.
    // - param types: Dart is bivariant.  We're contravariant.
    expect(isGroundType(Foo), isFalse);
    checkType(bar1, Foo, false);
    checkType(bar2, Foo, false);
    checkType(bar3, Foo);
    checkType(bar4, Foo);
    checkType(bar5, Foo);
    checkType(bar6, Foo, false);
    checkType(bar7, Foo);
    checkType(bar7, bar6.runtimeType);
    checkType(bar8, Foo);
    checkType(bar8, bar6.runtimeType, false);
    checkType(bar7, bar8.runtimeType, false);
    checkType(bar8, bar7.runtimeType, false);
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
}
