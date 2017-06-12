// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test using an identity hash.

import "package:expect/expect.dart";

abstract class BigGame {
  String get name;
}

// Giraffe overrides hashCode and provides its own identity hash.
class Giraffe implements BigGame {
  final String name;
  final int identityHash_;

  Giraffe(this.name) : identityHash_ = nextId() {}

  int get hashCode {
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

// Zebra relies on the system provided identity hash.
class Zebra implements BigGame {
  final String name;
  Zebra(this.name) {}
}

class SavannahTest {
  static void testMain() {
    Map<BigGame, String> savannah = new Map<BigGame, String>();

    Giraffe giraffe1 = new Giraffe("Tony");
    Giraffe giraffe2 = new Giraffe("Rose");
    savannah[giraffe1] = giraffe1.name;
    savannah[giraffe2] = giraffe2.name;
    print("giraffe1 hash: ${giraffe1.hashCode}");
    print("giraffe2 hash: ${giraffe2.hashCode}");

    var count = savannah.length;
    print("getCount is $count");
    Expect.equals(2, count);

    print("giraffe1: ${savannah[giraffe1]}");
    print("giraffe2: ${savannah[giraffe2]}");
    Expect.equals("Tony", savannah[giraffe1]);
    Expect.equals("Rose", savannah[giraffe2]);

    Zebra zebra1 = new Zebra("Paolo");
    Zebra zebra2 = new Zebra("Zeeta");
    savannah[zebra1] = zebra1.name;
    savannah[zebra2] = zebra2.name;
    print("zebra1 hash: ${zebra1.hashCode}");
    print("zebra2 hash: ${zebra2.hashCode}");

    count = savannah.length;
    print("getCount is $count");
    Expect.equals(4, count);

    print("zebra1: ${savannah[zebra1]}");
    print("zebra2: ${savannah[zebra2]}");
    Expect.equals("Paolo", savannah[zebra1]);
    Expect.equals("Zeeta", savannah[zebra2]);
  }
}

main() {
  SavannahTest.testMain();
}
