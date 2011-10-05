// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program testing NPE within string interpolation.

class A {
  A(String this.name) {}
  String name;
}

main() {
  A a = new A("Kermit");
  var s = "Hello Mr. ${a.name}";
  Expect.stringEquals("Hello Mr. Kermit", s);
  a = null;
  try {
    s = "Hello Mr. ${a.name}";
  } catch (NullPointerException e) {
    return;
  }
  Expect.fail("NullPointerException not thrown");
}
