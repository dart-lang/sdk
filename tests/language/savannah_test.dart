// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test using an identity hash.

interface BigGame extends Hashable {
  final String name;
}

class Giraffe implements BigGame {
  final String name;
  final int identityHash_;

  Giraffe(this.name) : identityHash_ = nextId() {}

  int hashCode() {
    return identityHash_;
  }

  // Calculate identity hash for a giraffe.
  static int nextId_;
  static int nextId() {
    if (nextId_ == null) {
      nextId_ = 17;
    }
    return nextId_++;
  }
}

class Zebra implements BigGame {
  final String name;
  Zebra(this.name) {}
}


class SavannahTest  {

  static void testMain() {
    Map<BigGame, String> savannah = new Map<BigGame, String>();
    Giraffe giraffe1 = new Giraffe("Tony");
    Giraffe giraffe2 = new Giraffe("Rose");
    savannah[giraffe1] = giraffe1.name;
    savannah[giraffe2] = giraffe2.name;

    var count = savannah.length;
    print("getCount is $count");
    Expect.equals(2, count);
    print("giraffe1: ${savannah[giraffe1]}");
    print("giraffe2: ${savannah[giraffe2]}");
    Expect.equals("Tony", savannah[giraffe1]);
    Expect.equals("Rose", savannah[giraffe2]);

    bool caught = false;
    Zebra zebra1 = new Zebra("Paul");
    Zebra zebra2 = new Zebra("Joe");
    try {
      savannah[zebra1] = zebra1.name;
      savannah[zebra2] = zebra2.name;
    } on NoSuchMethodError catch (e) {
      print("Caught: $e");
      caught = true;
    }
    Expect.equals(true, caught);

    count = savannah.length;
    print("getCount is $count");
    Expect.equals(2, count);

    caught = false;
    try {
      print("zebra1: ${savannah[zebra1]}");
      print("zebra2: ${savannah[zebra2]}");
    } on NoSuchMethodError catch (e) {
      print("Caught: $e");
      caught = true;
    }
    Expect.equals(true, caught);
  }

}

main() {
  SavannahTest.testMain();
}
