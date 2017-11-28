// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void main() {
  Map m = new Map();

  m[0] = 0;
  m[1] = 1;
  m[2] = m;

  Expect.equals('{0: 0, 1: 1, 2: {...}}', m.toString());

  // Throwing in the middle of a toString does not leave the
  // map as being visited
  ThrowOnToString err = new ThrowOnToString();
  m[1] = err;
  Expect.throws(m.toString, (e) => e == "Bad!");
  m[1] = 1;
  Expect.equals('{0: 0, 1: 1, 2: {...}}', m.toString());
  m[err] = 1;
  Expect.throws(m.toString, (e) => e == "Bad!");
  m.remove(err);
}

class ThrowOnToString {
  String toString() {
    throw "Bad!";
  }
}
