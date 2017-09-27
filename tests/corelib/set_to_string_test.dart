// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:collection";

void main() {
  Set s = new HashSet();
  s.add(1);
  Expect.equals("{1}", s.toString());
  s.remove(1);
  s.add(s);
  Expect.equals("{{...}}", s.toString());

  Queue q = new ListQueue(4);
  q.add(1);
  q.add(2);
  q.add(q);
  q.add(s);

  Expect.equals("{1, 2, {...}, {{...}}}", q.toString());

  // Throwing in the middle of a toString does not leave the
  // set as being visited
  q.addLast(new ThrowOnToString());
  Expect.throws(q.toString, (e) => e == "Bad!");
  q.removeLast();
  Expect.equals("{1, 2, {...}, {{...}}}", q.toString());
}

class ThrowOnToString {
  String toString() {
    throw "Bad!";
  }
}
