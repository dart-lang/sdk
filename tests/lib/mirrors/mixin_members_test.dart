// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";

import "package:expect/expect.dart";

class Fooer {
  foo1();
}

class S implements Fooer {
  foo1() {}
  foo2() {}
}

class M1 {
  bar1() {}
  bar2() {}
}

class M2 {
  baz1() {}
  baz2() {}
}

class C extends S with M1, M2 {}

main() {
  ClassMirror cm = reflectClass(C);
  Classmirror sM1M2 = cm.superclass;
  Classmirror sM1 = sM1M2.superclass;
  ClassMirror s = sM1.superclass;
  Expect.equals(0, cm.members.length);
  Expect.setEquals(sM1M2.members.keys,
                   [const Symbol("baz1"), const Symbol("baz2")]);
  Expect.setEquals(sM1M2.superinterfaces.map((e) => e.simpleName),
                   [const Symbol("M2")]);
  Expect.setEquals(sM1.members.keys,
                   [const Symbol("bar1"), const Symbol("bar2")]);
  Expect.setEquals(sM1.superinterfaces.map((e) => e.simpleName),
                   [const Symbol("M1")]);
  Expect.setEquals(s.members.keys.toSet(),
                   [const Symbol("foo1"), const Symbol("foo2")]);
  Expect.setEquals(s.superinterfaces.map((e) => e.simpleName),
                   [const Symbol("Fooer")]);
  Expect.equals(true, reflectClass(S) == s);
}
