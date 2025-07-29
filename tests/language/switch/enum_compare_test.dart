// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Ensure that switch statements with various types compare case expressions
// to the switch expression value correctly.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

enum Animal { cat, dog, mouse, lion, duck }

enum LongEnum {
  a,
  b,
  c,
  d,
  e,
  f,
  g,
  h,
  i,
  j,
  k,
  l,
  m,
  n,
  o,
  p,
  q,
  r,
  s,
  t,
  u,
  v,
  w,
  x,
  y,
  z,
  aa,
  ab,
  ac,
  ad,
  ae,
  af,
  ag,
  ah,
  ai,
  aj,
  ak,
  al,
  am,
  an,
  ao,
  ap,
  aq,
  ar,
  as,
  at,
  au,
  av,
  aw,
  ax,
  ay,
  az,
}

const List<String> strings = ['cat', 'dog', 'mouse', 'lion', 'duck'];
const List<int> ints = [1, 2, 3, 4, 5];
const List<bool> bools = [true, false];

void switches() {
  for (final animal in Animal.values) {
    switch (animal) {
      case Animal.cat:
        Expect.equals(animal, Animal.cat);
      case Animal.dog:
        Expect.equals(animal, Animal.dog);
      case Animal.mouse:
        Expect.equals(animal, Animal.mouse);
      case Animal.lion:
        Expect.equals(animal, Animal.lion);
      case Animal.duck:
        Expect.equals(animal, Animal.duck);
    }
  }

  final longEnum = LongEnum.ad;
  switch (longEnum) {
    case LongEnum.a:
      Expect.equals(LongEnum.a, LongEnum.a);
    case LongEnum.b:
      Expect.equals(LongEnum.b, LongEnum.b);
    default:
      Expect.equals(longEnum, LongEnum.ad);
  }

  for (final string in strings) {
    switch (string) {
      case 'cat':
        Expect.equals(string, 'cat');
      case 'dog':
        Expect.equals(string, 'dog');
      case 'mouse':
        Expect.equals(string, 'mouse');
      case 'lion':
        Expect.equals(string, 'lion');
      case 'duck':
        Expect.equals(string, 'duck');
      default:
        Expect.fail('Unknown string');
    }
  }

  for (final i in ints) {
    switch (i) {
      case 1:
        Expect.equals(i, 1);
      case 2:
        Expect.equals(i, 2);
      case 3:
        Expect.equals(i, 3);
      case 4:
        Expect.equals(i, 4);
      case 5:
        Expect.equals(i, 5);
      default:
        Expect.fail('Unknown int');
    }
  }

  for (final b in bools) {
    switch (b) {
      case true:
        Expect.isTrue(b);
      case false:
        Expect.isFalse(b);
    }
  }
}

Future<void> asyncSwitches() async {
  for (final animal in Animal.values) {
    switch (animal) {
      case Animal.cat:
        await 'something';
        Expect.equals(animal, Animal.cat);
      case Animal.dog:
        Expect.equals(animal, Animal.dog);
      case Animal.mouse:
        Expect.equals(animal, Animal.mouse);
      case Animal.lion:
        Expect.equals(animal, Animal.lion);
      case Animal.duck:
        Expect.equals(animal, Animal.duck);
    }
  }

  final longEnum = LongEnum.ad;
  switch (longEnum) {
    case LongEnum.a:
      await 'something';
      Expect.equals(LongEnum.a, LongEnum.a);
    case LongEnum.b:
      Expect.equals(LongEnum.b, LongEnum.b);
    default:
      Expect.equals(longEnum, LongEnum.ad);
  }

  for (final string in strings) {
    switch (string) {
      case 'cat':
        await 'something';
        Expect.equals(string, 'cat');
      case 'dog':
        Expect.equals(string, 'dog');
      case 'mouse':
        Expect.equals(string, 'mouse');
      case 'lion':
        Expect.equals(string, 'lion');
      case 'duck':
        Expect.equals(string, 'duck');
      default:
        Expect.fail('Unknown string');
    }
  }

  for (final i in ints) {
    switch (i) {
      case 1:
        await 'something';
        Expect.equals(i, 1);
      case 2:
        Expect.equals(i, 2);
      case 3:
        Expect.equals(i, 3);
      case 4:
        Expect.equals(i, 4);
      case 5:
        Expect.equals(i, 5);
      default:
        Expect.fail('Unknown int');
    }
  }

  for (final b in bools) {
    switch (b) {
      case true:
        await 'something';
        Expect.isTrue(b);
      case false:
        Expect.isFalse(b);
    }
  }
}

Future<void> main() async {
  asyncStart();

  switches();
  await asyncSwitches();

  asyncEnd();
}
