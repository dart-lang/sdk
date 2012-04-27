// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing default factories.

interface Vehicle default GoogleOne {
  Vehicle();
}


class Bike implements Vehicle {
  Bike.redOne() {}
}


interface SpaceShip default GoogleOne {
  SpaceShip();
}


class GoogleOne implements SpaceShip {
  GoogleOne.internal_() {}
  factory GoogleOne() { return new GoogleOne.internal_(); }
  factory Vehicle() { return new Bike.redOne(); }
}


class DefaultFactoryTest {
  static testMain() {
    Expect.equals(true, (new Bike.redOne()) is Bike);
    Expect.equals(true, (new SpaceShip()) is GoogleOne);
    Expect.equals(true, (new Vehicle()) is Bike);
  }
}

main() {
  DefaultFactoryTest.testMain();
}
