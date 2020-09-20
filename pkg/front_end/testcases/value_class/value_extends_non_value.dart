// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'value_class_support_lib.dart';

class Animal {
  final int numberOfLegs;
  Animal({required this.numberOfLegs});
}

@valueClass
class Cat extends Animal {
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

expect(Object? expected, Object? actual) {
  if (expected != actual) throw 'Expected=$expected, actual=$actual';
}