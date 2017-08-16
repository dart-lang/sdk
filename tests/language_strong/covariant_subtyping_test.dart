// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:expect/expect.dart';

bool isTypeError(e) => e is TypeError;

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
  Expect.throws(() {
    c.x = 'hello';
  }, isTypeError);

  Fields<dynamic> d = new Fields<int>();
  Expect.throws(() {
    c.x = 'hello';
  }, isTypeError);
}

testPrivateFields() {
  Fields<Object> c = new Fields<int>()..x = 42;
  c.m();
  Expect.equals(c._y, 42);

  Fields<Object> c2 = new Fields<String>()..x = 'hi';
  c2.n(c2);
  Expect.equals(c2._z, 'hi');
  Expect.throws(() {
    c.n(c2);
  }, isTypeError);
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
  Expect.throws(() {
    d.m(-1.1);
  }, isTypeError);
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
  Expect.throws(() => cObj.setterForT(), isTypeError);
  Expect.throws(() => (cObj.setterForT() as F<Object>), isTypeError);
  FnChecks<dynamic> cDyn = cInt;
  cDyn.setterForT(); // allowed fuzzy arrow
  Expect.throws(() => cDyn.setterForT()('hi'), isTypeError); // dcall throws
  cInt.setterForT()(42);
  Expect.equals(cObj.getT(), 42);
}

testTearoffReturningFunctionType() {
  FnChecks<int> cInt = new FnChecks<int>();
  FnChecks<Object> cObj = cInt;

  Expect.throws(
      () => cObj.setterForT, isTypeError, 'unsound tear-off throws at runtime');
  Expect.equals(cInt.setterForT, cInt.setterForT, 'sound tear-off works');
}

testFieldOfFunctionType() {
  FnChecks<Object> c = new FnChecks<String>()..f = (String b) {};
  Expect.throws(() {
    F<Object> f = c.f;
  }, isTypeError);
  Expect.throws(() {
    Object f = c.f;
  }, isTypeError);
  Expect.throws(() => c.f, isTypeError);
  Expect.throws(() => c.f(42), isTypeError);
  Expect.throws(() => c.f('hi'), isTypeError);
  FnChecks<String> cStr = c;
  cStr.f('hi');
  FnChecks<dynamic> cDyn = c;
  cDyn.f; // allowed fuzzy arrow
  Expect.throws(() => cDyn.f(42), isTypeError); // dcall throws
}

testFieldOfGenericFunctionType() {
  FnChecks<Object> c = new FnChecks<num>()
    ..g = <S extends num>(S s) => s.isNegative;

  Expect.throws(() {
    G<Object> g = c.g;
  }, isTypeError);
  Expect.throws(() {
    var g = c.g;
  }, isTypeError);
  Expect.throws(() {
    c.g<String>('hi');
  }, isTypeError);
  Expect.throws(() {
    c.g<int>(42);
  }, isTypeError);
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
  Expect.throws(() {
    i.add('hi');
  }, isTypeError);
  Expect.throws(() {
    j.add('hi');
  }, isTypeError);
  // TODO(jmesserly): this should also throw. It does not because DDC's
  // technique for generating mixin aliases (mixin applications of the form
  // `class X = Object with Y /* optional implements */;`) does not allow
  // adding any methods in the class. The normal technique of generating
  // a method that performs the check and then calls `super` will not work,
  // because there is no superclass to call. We will need some sort of
  // special case code to implement this, perhaps move the original
  // method to a symbol, then generate a wrapper with the original method name,
  // that checks and calls it.
  k.add('hi');
}

abstract class GenericAdd<T> {
  add<S extends T>(S t);
}

class GenericAdder implements GenericAdd<num> {
  num _t = 0;
  add<T extends num>(T t) {
    _t = t;
  }
}

testGenericMethodBounds() {
  GenericAdd<Object> i = new GenericAdder();
  // TODO(jmesserly): should generic method bounds use a different error type?
  // This seems wrong. Also this Error type is not exposed from dart:core.
  Expect.throws(() {
    i.add('hi');
  }, (e) => '${e.runtimeType}'.startsWith('StrongModeError'));
  Expect.throws(() {
    i.add<String>(null);
  }, (e) => '${e.runtimeType}'.startsWith('StrongModeError'));
  i.add(null);
  i.add(42);
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
  Expect.throws(() {
    f(new Object());
  }, isTypeError);
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
}
