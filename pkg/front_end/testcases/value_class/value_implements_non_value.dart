// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'value_class_support_lib.dart';

class Animal {
  final int numberOfLegs;
}

@valueClass
class Cat implements Animal {
  final int numberOfLegs;
  final int numberOfWhiskers;
}

abstract class Animal2 {
  int get numberOfLegs;
}

@valueClass
class Cat2 implements Animal2 {
  final int numberOfLegs;
  final int numberOfWhiskers;
}


main() {
  Cat firstCat = Cat(numberOfLegs: 4, numberOfWhiskers: 10);
  Cat secondCat = Cat(numberOfLegs: 4, numberOfWhiskers: 10);
  Cat thirdCat = Cat(numberOfLegs: 4, numberOfWhiskers: 0);

  expect(true, firstCat == secondCat);
  expect(false, firstCat == thirdCat);

  expect(true, firstCat.hashCode == secondCat.hashCode);
  expect(false, firstCat.hashCode == thirdCat.hashCode);

  Cat2 firstCat2 = Cat2(numberOfLegs: 4, numberOfWhiskers: 10);
  Cat2 secondCat2 = Cat2(numberOfLegs: 4, numberOfWhiskers: 10);
  Cat2 thirdCat2 = Cat2(numberOfLegs: 4, numberOfWhiskers: 0);

  expect(true, firstCat2 == secondCat2);
  expect(false, firstCat2 == thirdCat2);

  expect(true, firstCat2.hashCode == secondCat2.hashCode);
  expect(false, firstCat2.hashCode == thirdCat2.hashCode);
}

expect(Object? expected, Object? actual) {
  if (expected != actual) throw 'Expected=$expected, actual=$actual';
}