// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test megamorphic, but single target field load.
// VMOptions=--optimization-counter-threshold=10

import "package:expect/expect.dart";

class Base {
  var f;
}

class A extends Base {
  A() {
    this.f = 0;
  }
}

class B extends Base {
  B() {
    this.f = 1;
  }
}

class C extends Base {
  C() {
    this.f = 2;
  }
}

class D extends Base {
  D() {
    this.f = 3;
  }
}

class E extends Base {
  E() {
    this.f = 4;
  }
}

class F extends Base {
  F() {
    this.f = 5;
  }
}

class G extends Base {
  G() {
    this.f = 6;
  }
}

class H extends Base {
  H() {
    this.f = 7;
  }
}

class I extends Base {
  I() {
    this.f = 8;
  }
}

class J extends Base {
  J() {
    this.f = 9;
  }
}

class K extends Base {
  K() {
    this.f = 10;
  }
}

class L extends Base {
  L() {
    this.f = 11;
  }
}

class M extends Base {
  M() {
    this.f = 12;
  }
}

class N extends Base {
  N() {
    this.f = 13;
  }
}

class O extends Base {
  O() {
    this.f = 14;
  }
}

class P extends Base {
  P() {
    this.f = 15;
  }
}

class Q extends Base {
  Q() {
    this.f = 16;
  }
}

class R extends Base {
  R() {
    this.f = 17;
  }
}

class S extends Base {
  S() {
    this.f = 18;
  }
}

class T extends Base {
  T() {
    this.f = 19;
  }
}

class U extends Base {
  U() {
    this.f = 20;
  }
}

class V extends Base {
  V() {
    this.f = 21;
  }
}

class W extends Base {
  V() {
    this.f = 22;
  }
}

class X extends Base {
  V() {
    this.f = 21;
  }
}

class Y extends Base {
  V() {
    this.f = 24;
  }
}

class Z extends Base {
  V() {
    this.f = 21;
  }
}

allocateObjects() {
  var list = new List();
  list.add(new A());
  list.add(new B());
  list.add(new C());
  list.add(new D());
  list.add(new E());
  list.add(new F());
  list.add(new G());
  list.add(new H());
  list.add(new I());
  list.add(new J());
  list.add(new K());
  list.add(new L());
  list.add(new M());
  list.add(new N());
  list.add(new O());
  list.add(new P());
  list.add(new Q());
  list.add(new R());
  list.add(new S());
  list.add(new T());
  list.add(new U());
  list.add(new V());
  return list;
}

callThemAll(var list) {
  for (var i = 0; i < list.length; i++) {
    Expect.equals(i, list[i].f);
  }
}

main() {
  var list = allocateObjects();
  // Make sure the optimizer triggers the compilation of callThemAll.
  for (var i = 0; i < 20; i++) {
    callThemAll(list);
  }
}
