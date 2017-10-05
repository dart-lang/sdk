// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that arrays from const array literals are immutable.

import "package:expect/expect.dart";

class ListLiteral3Test {
  static const List<String> canonicalJoke = const ["knock", "knock"];

  static testMain() {
    List<String> joke = const ["knock", "knock"];
    // Elements of canonical lists are canonicalized.
    Expect.identical(joke, canonicalJoke);
    Expect.identical(joke[0], joke[1]);
    Expect.identical(joke[0], canonicalJoke[0]);

    // Lists from literals are immutable.
    Expect.throws(() {
      joke[0] = "sock";
    }, (e) => e is UnsupportedError);
    Expect.identical(joke[0], joke[1]);

    // Make sure lists allocated at runtime are mutable and are
    // not canonicalized.
    List<String> lame_joke = ["knock", "knock"]; // Invokes operator new.
    Expect.identical(joke[1], lame_joke[1]);
    // Operator new creates a mutable list.
    Expect.equals(false, identical(joke, lame_joke));
    lame_joke[1] = "who";
    Expect.identical("who", lame_joke[1]);

    // Elements of canonical lists are canonicalized.
    List<List<int>> a = const <List<int>>[
      const [1, 2],
      const [1, 2]
    ];
    Expect.identical(a[0], a[1]);
    Expect.identical(a[0][0], a[1][0]);
    Expect.throws(() {
      a[0][0] = 42;
    }, (e) => e is UnsupportedError);

    List<List<double>> b = const [
      const [1.0, 2.0],
      const [1.0, 2.0]
    ];
    Expect.identical(b[0], b[1]);
    Expect.equals(true, b[0][0] == 1.0);
    Expect.identical(b[0][0], b[1][0]);
    Expect.throws(() {
      b[0][0] = 42.0;
    }, (e) => e is UnsupportedError);
  }
}

main() {
  ListLiteral3Test.testMain();
}
