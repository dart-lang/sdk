// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const String valueClass = "valueClass";

@valueClass
class Animal {
  final int numberOfLegs;
}

main() {
  Animal firstAnimal = Animal(numberOfLegs: 4);
  Animal secondAnimal = Animal(numberOfLegs: 4);
  Animal thirdAnimal = Animal(numberOfLegs: 3);

  expect(true, firstAnimal == secondAnimal);
  expect(false, firstAnimal == thirdAnimal);

  expect(true, firstAnimal.hashCode == secondAnimal.hashCode);
  expect(false, firstAnimal.hashCode == thirdAnimal.hashCode);
}

expect(expected, actual, [expectNull = false]) {
  if (expectNull) {
    expected = null;
  }
  if (expected != actual) {
    throw 'Mismatch: expected=$expected, actual=$actual';
  }
}