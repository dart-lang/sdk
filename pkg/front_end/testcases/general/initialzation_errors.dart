// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int x;
  A()
      : this.x = 41,
        this.x = 42 {}
}

class B {
  final int x;
  B()
      : this.x = 41,
        this.x = 42 {}
}

class C {
  final int x = 2;
  C()
      : this.x = 41,
        this.x = 42 {}
}

class D {
  final int x;
  final int y;
  D()
      : this.x = 41,
        this.named(),
        this.y = 42 {}
  D.named()
      : this.x = 41,
        this.y = 42 {}
}

class E {
  final int x;
  final int y;
  E()
      : this.named(),
        this.x = 1,
        this.y = 2 {}
  E.named()
      : this.x = 41,
        this.y = 42 {}
  E.named2()
      : this.x = 1,
        this.named(),
        this.y = 2;
  E.named3()
      : super(),
        this.named(),
        this.x = 1,
        this.y = 2;
  E.named4()
      : this.x = 1,
        this.y = 2,
        this.named();
  E.named5()
      : assert(true),
        this.named();
  E.named6()
      : this.named(),
        assert(true);
}

class F {
  F()
      : this.named(),
        super() {}
  F.named() {}
}

class G {
  G()
      : super(),
        this.named(),
        super() {}
  G.named() {}
}

class H {
  H()
      : this.named(),
        this.named();
  H.named() {}
}

class I {
  I()
      : super(),
        super() {}
}

class J {
  int x;
  J()
      : super(),
        this.x = 42 {}
}

main() {}
