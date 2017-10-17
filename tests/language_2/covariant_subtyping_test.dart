// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:expect/expect.dart';

class Fields<T> {
  T x;
  T _y;
  T _z;

  m() {
    _y = x;
  }

  n(Fields<T> c) {
    c._z = x;
  }
}

testField() {
  Fields<Object> c = new Fields<int>();
  Expect.throwsTypeError(() => c.x = 'hello');

  Fields<dynamic> d = new Fields<int>();
  Expect.throwsTypeError(() => c.x = 'hello');
}

testPrivateFields() {
  Fields<Object> c = new Fields<int>()..x = 42;
  c.m();
  Expect.equals(c._y, 42);

  Fields<Object> c2 = new Fields<String>()..x = 'hi';
  c2.n(c2);
  Expect.equals(c2._z, 'hi');
  Expect.throwsTypeError(() => c.n(c2));
  Expect.equals(c2._z, 'hi');
}

class NumBounds<T extends num> {
  bool m(T t) => t.isNegative;
}

class MethodTakesNum extends NumBounds<int> {
  bool m(num obj) => obj.isNegative; // does not need check
}

class MethodTakesInt extends NumBounds<int> {
  bool m(int obj) => obj.isNegative; // needs a check
}

testClassBounds() {
  NumBounds<num> d = new MethodTakesNum();
  Expect.equals(d.m(-1.1), true);
  d = new MethodTakesInt();
  Expect.throwsTypeError(() => d.m(-1.1));
}

typedef void F<T>(T t);
typedef G<T> = void Function<S extends T>(S s);

class FnChecks<T> {
  F<T> f;
  G<T> g;
  T _t;
  T getT() => _t;
  F<T> setterForT() {
    return (T t) {
      _t = t;
    };
  }
}

testReturnOfFunctionType() {
  FnChecks<int> cInt = new FnChecks<int>();
  FnChecks<Object> cObj = cInt;
  Expect.throwsTypeError(() => cObj.setterForT());
  Expect.throwsTypeError(() => (cObj.setterForT() as F<Object>));
  FnChecks<dynamic> cDyn = cInt;
  cDyn.setterForT(); // allowed fuzzy arrow
  Expect.throwsTypeError(() => cDyn.setterForT()('hi')); // dcall throws
  cInt.setterForT()(42);
  Expect.equals(cObj.getT(), 42);
}

testTearoffReturningFunctionType() {
  FnChecks<int> cInt = new FnChecks<int>();
  FnChecks<Object> cObj = cInt;

  Expect.throwsTypeError(
      () => cObj.setterForT, 'unsound tear-off throws at runtime');
  Expect.equals(cInt.setterForT, cInt.setterForT, 'sound tear-off works');
}

testFieldOfFunctionType() {
  FnChecks<Object> c = new FnChecks<String>()..f = (String b) {};
  Expect.throwsTypeError(() {
    F<Object> f = c.f;
  });
  Expect.throwsTypeError(() {
    Object f = c.f;
  });
  Expect.throwsTypeError(() => c.f);
  Expect.throwsTypeError(() => c.f(42));
  Expect.throwsTypeError(() => c.f('hi'));
  FnChecks<String> cStr = c;
  cStr.f('hi');
  FnChecks<dynamic> cDyn = c;
  cDyn.f; // allowed fuzzy arrow
  Expect.throwsTypeError(() => cDyn.f(42)); // dcall throws
}

testFieldOfGenericFunctionType() {
  FnChecks<Object> c = new FnChecks<num>()
    ..g = <S extends num>(S s) => s.isNegative;

  Expect.throwsTypeError(() {
    G<Object> g = c.g;
  });
  Expect.throwsTypeError(() {
    var g = c.g;
  });
  Expect.throwsTypeError(() => c.g<String>('hi'));
  Expect.throwsTypeError(() => c.g<int>(42));
  FnChecks<num> cNum = c;
  cNum.g(42);
}

class Base {
  int _t = 0;
  add(int t) {
    _t += t;
  }
}

abstract class I<T> {
  add(T t);
}

class ExtendsBase extends Base implements I<int> {}

class MixinBase extends Object with Base implements I<int> {}

class MixinBase2 = Object with Base implements I<int>;

testMixinApplication() {
  I<Object> i = new ExtendsBase();
  I<Object> j = new MixinBase();
  I<Object> k = new MixinBase2();
  Expect.throwsTypeError(() => i.add('hi'));
  Expect.throwsTypeError(() => j.add('hi'));
  Expect.throwsTypeError(() => k.add('hi'));
}

class GenericMethodBounds<T> {
  Type get t => T;
  GenericMethodBounds<E> foo<E extends T>() => new GenericMethodBounds<E>();
  GenericMethodBounds<E> bar<E extends void Function(T)>() =>
      new GenericMethodBounds<E>();
}

class GenericMethodBoundsDerived extends GenericMethodBounds<num> {
  GenericMethodBounds<E> foo<E extends num>() => new GenericMethodBounds<E>();
  GenericMethodBounds<E> bar<E extends void Function(num)>() =>
      new GenericMethodBounds<E>();
}

GenericMethodBounds<E> Function<E extends T>() genericFunctionWithBounds<T>() {
  inner<E extends T>() => new GenericMethodBounds<E>();
  return inner;
}

testGenericMethodBounds() {
  test(GenericMethodBounds<Object> g) {
    Expect.throwsTypeError(() => g.foo<String>());
    Expect.throwsTypeError(() => g.foo());
    Expect.equals(g.foo<Null>().t, Null);
    Expect.equals(g.foo<int>().t, int);
    Expect.isFalse(g.foo<int>() is GenericMethodBounds<double>);
    g.bar<Function(Object)>();
    dynamic d = g;
    d.bar<Function(num)>();
    Expect.throwsTypeError(() => d.bar<Function(String)>());
    Expect.throwsTypeError(() => d.bar<Function(Null)>());
  }

  test(new GenericMethodBounds<num>());
  test(new GenericMethodBounds<int>());
  test(new GenericMethodBoundsDerived());
  test(genericFunctionWithBounds<num>()<int>());
}

class ClassF<T> {
  T x;
  void call(T t) {
    x = t;
  }
}

testCallMethod() {
  ClassF<int> cc = new ClassF<int>();
  ClassF<Object> ca = cc; // An upcast, per covariance.
  F<Object> f = ca;
  Expect.equals(f.runtimeType.toString(), 'ClassF<int>');
  Expect.throwsTypeError(() => f(new Object()));
}

class TearOff<T> {
  method1(T t) => null; // needs check
  method2(Function(T) takesT) => null;
  method3(T Function() returnsT) => null; // needs check
  method4(Function(Function(T)) takesTakesT) => null; // needs check
  method5(Function(T Function()) takesReturnsT) => null;
  method6(Function(T) Function() returnsTakesT) => null;
  method7(T Function() Function() returnsReturnsT) => null; // needs check
}

testTearOffRuntimeType() {
  expectRTTI(tearoff, type) => Expect.equals('${tearoff.runtimeType}', type,
      'covariant params should reify with Object as their type');

  TearOff<num> t = new TearOff<int>();
  expectRTTI(t.method1, '(Object) -> dynamic');

  expectRTTI(t.method2, '((int) -> dynamic) -> dynamic');
  expectRTTI(t.method3, '(Object) -> dynamic');

  expectRTTI(t.method4, '(Object) -> dynamic');
  expectRTTI(t.method5, '((() -> int) -> dynamic) -> dynamic');
  expectRTTI(t.method6, '(() -> (int) -> dynamic) -> dynamic');
  expectRTTI(t.method7, '(Object) -> dynamic');
}

main() {
  testField();
  testPrivateFields();
  testClassBounds();
  testReturnOfFunctionType();
  testTearoffReturningFunctionType();
  testFieldOfFunctionType();
  testFieldOfGenericFunctionType();
  testMixinApplication();
  testGenericMethodBounds();
  testCallMethod();
  testTearOffRuntimeType();
}
