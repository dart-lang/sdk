// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class B {
  const B();
}

class C<T> {
  const C();
}

class D<T> extends C<T> {
  factory D() {
    return new E<T>();
  }
}

class E<T> extends D<T> {
} 


// SnippetTestCase only returns generated JS for the Main class.
class Main {
 static void main() {
    var a = 0;
    var _marker_0 = 1;
    var _marker_B1 = const B();
    var _marker_B2 = new B();
    var _marker_C1 = const C();
    var _marker_C2 = const C<String>();
    var _marker_C3 = new C();
    var _marker_C4 = new C<Object>();
    var _marker_D1 = new D();
    var _marker_D2 = new D<String>();

    a = _marker_B1 is B;
    a = _marker_C1 is C;
    a = _marker_C2 is C<String>;
    a = _marker_C4 is C<Object>;
    a = _marker_C4 is Object;
    a = _marker_D1 is D;
    a = _marker_D2 is D<String>;
  }
}

main() {
  Main.main();
}
