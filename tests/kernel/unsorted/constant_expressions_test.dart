// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

const int42 = 40 + 2;
const stringAB = 'a' + 'b';
const stringAB2 = 'a' + 'b';
const list123 = const [1, 2, 3];
const mapABC = const {'a': 'b', 'b': 'c'};

const boxInt42 = const Box(int42);
const boxStringAB = const Box(stringAB);

class Box {
  final value;
  const Box(this.value);
}

returnPositional([a = const Box('posi' + 'tional')]) => a;

returnNamed({a: const Box('nam' + 'ed')}) => a;

returnSwitchCasedValue(value) {
  switch (value) {
    case const Box(42):
      return 42;
    case const Box('abc'):
      return 'abc';
    case const Box(const Box('abc')):
      return const Box('abc');
    default:
      return 'default';
  }
}

testConstantExpressions() {
  Expect.isTrue(identical(const Box(40 + 2), const Box(40 + 2)));
  Expect.isTrue(identical(const Box('a' + 'b'), const Box('ab')));
  Expect.isTrue(
      identical(const Box(const Box(40 + 2)), const Box(const Box(42))));
  Expect.isTrue(
      identical(const Box(const Box('a' + 'b')), const Box(const Box('ab'))));
}

testConstantFieldValues() {
  Expect.isTrue(identical(42, int42));
  Expect.isTrue(identical(stringAB, stringAB2));
  Expect.isTrue(identical(const Box(42), boxInt42));
  Expect.isTrue(identical(const Box('ab'), boxStringAB));
}

testConstantFunctionParameters() {
  Expect.isTrue(identical(const Box('positional'), returnPositional()));
  Expect.isTrue(identical(const Box('named'), returnNamed()));
  Expect
      .isTrue(identical(const Box('abc'), returnPositional(const Box('abc'))));
  Expect.isTrue(identical(const Box('def'), returnNamed(a: const Box('def'))));
}

testConstantSwitchExpressions() {
  Expect.isTrue(returnSwitchCasedValue(const Box(42)) == 42);
  Expect.isTrue(returnSwitchCasedValue(const Box('abc')) == 'abc');
  Expect.isTrue(
      returnSwitchCasedValue(const Box(const Box('abc'))) == const Box('abc'));
  Expect
      .isTrue(returnSwitchCasedValue(const Box('go-to-default')) == 'default');
}

testConstantLocalVariables() {
  const a = 'a';
  const b = a + 'b';
  const c = b + 'c';
  const box = const Box(c);
  Expect.isTrue(identical(const Box('abc'), box));
}

testComplextConstLiterals() {
  Expect.isTrue(identical(const [1, 2, 3], const [1, 2, 3]));
  Expect.isTrue(identical(const [1, 2, 3], list123));
  Expect.isTrue(
      identical(const {'a': 'b', 'b': 'c'}, const {'a': 'b', 'b': 'c'}));
  Expect.isTrue(identical(const {'a': 'b', 'b': 'c'}, mapABC));

  Expect.isTrue(mapABC['a'] == 'b');
  Expect.isTrue(mapABC['b'] == 'c');
  Expect.isTrue(mapABC.length == 2);

  Expect.isTrue(list123[0] == 1);
  Expect.isTrue(list123[1] == 2);
  Expect.isTrue(list123[2] == 3);
  Expect.isTrue(list123.length == 3);
}

main() {
  testConstantExpressions();
  testConstantFieldValues();
  testConstantFunctionParameters();
  testConstantSwitchExpressions();
  testComplextConstLiterals();
  testConstantExpressions();
  testConstantLocalVariables();
}
