// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that arrays from const array literals are immutable.

class ListLiteral3Test {

  static const List<String> canonicalJoke = const ["knock", "knock"];

  static testMain() {

    List<String> joke = const ["knock", "knock"];
    // Elements of canonical lists are canonicalized.
    Expect.equals(true, joke === canonicalJoke);
    Expect.equals(true, joke[0] === joke[1]);
    Expect.equals(true, joke[0] === canonicalJoke[0]);

    // Lists from literals are immutable.
    bool caughtException = false;
    try {
      joke[0] = "sock";
    } on UnsupportedError catch (e) {
      caughtException = true;
    }
    Expect.equals(true, caughtException);
    Expect.equals(true, joke[0] === joke[1]);

    // Make sure lists allocated at runtime are mutable and are
    // not canonicalized.
    List<String> lame_joke = ["knock", "knock"];  // Invokes operator new.
    Expect.equals(true, joke[1] === lame_joke[1]);
    // Operator new creates a mutable list.
    Expect.equals(false, joke === lame_joke);
    lame_joke[1] = "who";
    Expect.equals(true, "who" === lame_joke[1]);

    // Elements of canonical lists are canonicalized.
    List<List<int>> a = const <List<int>>[ const [1, 2], const [1, 2]];
    Expect.equals(true, a[0] === a[1]);
    Expect.equals(true, a[0][0] === a[1][0]);
    try {
      caughtException = false;
      a[0][0] = 42;
    } on UnsupportedError catch (e) {
      caughtException = true;
    }
    Expect.equals(true, caughtException);

    List<List<double>> b = const [ const [1.0, 2.0], const [1.0, 2.0]];
    Expect.equals(true, b[0] === b[1]);
    Expect.equals(true, b[0][0] === 1.0);
    Expect.equals(true, b[0][0] === b[1][0]);
    try {
      caughtException = false;
      b[0][0] = 42.0;
    } on UnsupportedError catch (e) {
      caughtException = true;
    }
    Expect.equals(true, caughtException);
  }
}

main() {
  ListLiteral3Test.testMain();
}
