// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program testing that NoSuchMethod is properly called.

import "package:expect/expect.dart";

class Cat {
  bool eatFood(String food) => true;
  String scratch(String furniture) => 'purr';
  String mood = '';
}

class MockCat implements Cat {
  dynamic noSuchMethod(Invocation invocation) {
    var arg = invocation.positionalArguments[0];
    return arg is String && arg.isNotEmpty;
  }
}

class MockCat2 extends MockCat {
  // this apparently works.
  noSuchMethod(_);
}

class MockCat3 extends MockCat2 implements Cat {
  bool eatFood(String food, {double amount});
  String scratch(String furniture, [String? furniture2]);

  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #scratch) {
      return invocation.positionalArguments.join(',');
    }

    return (invocation.positionalArguments[0] as String).isNotEmpty &&
        invocation.namedArguments[#amount] > 0.5;
  }
}

class MockWithGenerics {
  List<Type> doStuff<T>(T t);

  noSuchMethod(i) => (i as dynamic).typeArguments;
}

class MockWithGetterSetter {
  get getter;
  set setter(value);

  late Invocation invocation;
  noSuchMethod(i) {
    invocation = i;
  }
}

class Callable {
  int call() => 1;
  int m() => 2;
}

class MockCallable implements Callable {
  noSuchMethod(i) => i.memberName == #call ? 42 : 0;
}

void main() {
  MockCat mock = new MockCat();
  Expect.isTrue((mock as dynamic).eatFood("cat food"));
  Expect.isFalse(mock.eatFood(""));
  mock.mood = 'sleepy';
  (mock as dynamic).mood = 'playful';
  Expect.throwsTypeError(() {
    (mock as dynamic).mood = 42;
  });

  // In strong mode this will be a runtime type error:
  // bool is not a String. VM will fail with noSuchMethod +.
  Expect.throws(() => mock.scratch("couch") + '');

  var mock2 = new MockCat2();
  Expect.isTrue(mock2.eatFood("cat food"));

  var mock3 = new MockCat3();
  Expect.isTrue(mock3.eatFood("cat food", amount: 0.9));
  Expect.isFalse(mock3.eatFood("cat food", amount: 0.3));
  Expect.equals("chair,null", mock3.scratch("chair"));
  Expect.equals("chair,couch", mock3.scratch("chair", "couch"));
  Expect.equals("chair,null", mock3.scratch("chair", null));
  Expect.equals("chair,", mock3.scratch("chair", ""));

  var g = new MockWithGenerics();
  Expect.listEquals([int], g.doStuff(42));
  Expect.listEquals([num], g.doStuff<num>(42));
  Expect.listEquals([String], g.doStuff('hi'));

  var s = new MockWithGetterSetter();
  s.getter;
  Expect.equals(0, s.invocation.positionalArguments.length);
  Expect.isTrue(s.invocation.isGetter);
  Expect.isFalse(s.invocation.isSetter);
  Expect.isFalse(s.invocation.isMethod);
  s.setter = 42;
  Expect.equals(42, s.invocation.positionalArguments.single);
  Expect.isFalse(s.invocation.isGetter);
  Expect.isTrue(s.invocation.isSetter);
  Expect.isFalse(s.invocation.isMethod);

  testMockTearoffs();
  testMockCallable();
  testMockCallableTearoff();
}

testMockCallable() {
  Callable call = new MockCallable();
  Expect.equals(42, call());
  Expect.equals(42, (call as dynamic)());
  Expect.equals(0, call.m());
  Expect.equals(0, (call as dynamic).m());
}

testMockCallableTearoff() {
  var mock = new MockCallable();
  Function f = mock;
  Expect.equals(42, f());
  Expect.equals(42, (f as dynamic)());
  Expect.equals(f, mock.call);
  Expect.equals(f.call, mock.call);
  Expect.equals((f as dynamic).call, mock.call);
  Expect.equals(f.call, (mock as dynamic).call);
}

typedef bool EatFoodType(String food);

testMockTearoffs() {
  var mock2 = new MockCat2();
  var eat = mock2.eatFood;
  var eat2 = (mock2 as dynamic).eatFood;

  Expect.isTrue(eat is EatFoodType, 'eat is EatFoodType');
  Expect.isTrue(eat2 is EatFoodType, 'eat2 is EatFoodType');
  Expect.equals(eat, eat2, 'eat == eat2');
  Expect.isTrue(eat.runtimeType == eat2.runtimeType,
      'eat.runtimeType == eat2.runtimeType');

  Expect.isTrue(eat("cat food"), 'eat("cat food")');
  Expect.isFalse(eat(""), 'eat("")');
  Expect.isTrue(eat2("cat food"), 'eat2("cat food")');
  Expect.isFalse(eat2(""), 'eat2("")');

  var g = new MockWithGenerics();
  var doStuff = g.doStuff;
  var doStuff2 = (g as dynamic).doStuff;

  Expect.equals(doStuff, doStuff2, 'doStuff == doStuff2');
  Expect.equals(doStuff.runtimeType, doStuff2.runtimeType,
      'doStuff.runtimeType == doStuff2.runtimeType');

  Expect.listEquals([int], doStuff(42));
  Expect.listEquals([num], doStuff<num>(42));
  Expect.listEquals([String], doStuff('hi'));

  // no inference happens because `doStuff2` is dynamic.
  Expect.listEquals([num], doStuff2<num>(42));
  expectIsDynamicOrObject(List types) {
    Expect.equals(1, types.length);
    var t = types[0];
    // TODO(jmesserly): allows either type because of
    // https://github.com/dart-lang/sdk/issues/32483
    Expect.isTrue(t == dynamic || t == Object, '$t == dynamic || $t == Object');
  }

  expectIsDynamicOrObject(doStuff2(42));
  expectIsDynamicOrObject(doStuff2('hi'));
}
