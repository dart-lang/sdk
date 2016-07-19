// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program testing that NoSuchMethod is properly called.

import "package:expect/expect.dart";

class Cat {
  bool eatFood(String food) => true;
  int scratch(String furniture) => 100;
}

class MockCat implements Cat {
  dynamic noSuchMethod(Invocation invocation) {
    return (invocation.positionalArguments[0] as String).isNotEmpty;
  }
}


class MockCat2 extends MockCat {
  // this apparently works.
  noSuchMethod(_);
}

class MockCat3 extends MockCat2 implements Cat {
  bool eatFood(String food, {double amount});
  int scratch(String furniture, [String furniture2]);

  dynamic noSuchMethod(Invocation invocation) {
    return (invocation.positionalArguments[0] as String).isNotEmpty &&
        invocation.namedArguments[#amount] > 0.5;
  }
}


class MockWithGenerics {
  /*=T*/ doStuff/*<T>*/(/*=T*/ t);

  noSuchMethod(i) => i.positionalArguments[0] + 100;
}


void main() {
  MockCat mock = new MockCat();
  Expect.isTrue((mock as dynamic).eatFood("cat food"));
  Expect.isFalse(mock.eatFood(""));

  // In strong mode this will be a runtime type error:
  // bool is not an int. VM will fail with noSuchMethod +.
  Expect.throws(() => mock.scratch("couch") + 0);

  var mock2 = new MockCat2();
  Expect.isTrue(mock2.eatFood("cat food"));

  var mock3 = new MockCat3();
  Expect.isTrue(mock3.eatFood("cat food", amount: 0.9));
  Expect.isFalse(mock3.eatFood("cat food", amount: 0.3));

  var g = new MockWithGenerics();
  Expect.equals(g.doStuff(42), 142);
  Expect.throws(() => g.doStuff('hi'));
}
