// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of LibraryPrefixes.lib;

class LibraryPrefixes {
  static void main(var expectEquals) {
    var a = Constants.PI;
    var b = other.Constants.PI;
    expectEquals(3.14, a);
    expectEquals(3.14, b);

    expectEquals(1, Constants.foo);
    expectEquals(2, other.Constants.foo);

    expectEquals(-1, A.y);
    expectEquals(0, other.A.y);

    expectEquals(1, new A().x);
    expectEquals(2, new other.A().x);

    expectEquals(3, new A.named().x);
    expectEquals(4, new other.A.named().x);

    expectEquals(3, new A.fac().x);
    expectEquals(4, new other.A.fac().x);

    expectEquals(1, new B().x);
    expectEquals(2, new other.B().x);

    expectEquals(8, new B.named().x);
    expectEquals(13, new other.B.named().x);

    expectEquals(8, new B.fac().x);
    expectEquals(13, new other.B.fac().x);

    expectEquals(1, const C().x);
    expectEquals(2, const other.C().x);

    expectEquals(3, const C.named().x);
    expectEquals(4, const other.C.named().x);

    expectEquals(3, new C.fac().x);
    expectEquals(4, new other.C.fac().x);

    expectEquals(1, const D().x);
    expectEquals(2, const other.D().x);

    expectEquals(8, const D.named().x);
    expectEquals(13, const other.D.named().x);

    expectEquals(8, new D.fac().x);
    expectEquals(13, new other.D.fac().x);

    expectEquals(0, E.foo());
    expectEquals(3, other.E.foo());

    expectEquals(1, new E().bar());
    expectEquals(4, new other.E().bar());

    expectEquals(9, new E().toto(7)());
    expectEquals(16, new other.E().toto(11)());

    expectEquals(111, (new E.fun(100).f)());
    expectEquals(1313, (new other.E.fun(1300).f)());

    expectEquals(999, E.fooo(900)());
    expectEquals(2048, other.E.fooo(1024)());
  }
}
