// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing super operator calls


class A {
  String val = "";
  operator + (String s) {
    val = val + s;
    return this;
  }
}

class B extends A {
  operator + (String s) {
    super + (s + s);
    return this;
  }
}

main () {
  var a = new A();
  a = a + "William";
  Expect.equals("William", a.val);

  a = new B();
  a += "Tell";
  Expect.equals("TellTell", a.val);
}
