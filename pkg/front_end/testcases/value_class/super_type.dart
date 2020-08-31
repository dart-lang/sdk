// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const String valueClass = "valueClass";

@valueClass
class Animal {
  final int numberOfLegs;
}

@valueClass
class Cat implements Animal {
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
}

expect(expected, actual, [expectNull = false]) {
  if (expectNull) {
    expected = null;
  }
  if (expected != actual) {
    throw 'Mismatch: expected=$expected, actual=$actual';
  }
}