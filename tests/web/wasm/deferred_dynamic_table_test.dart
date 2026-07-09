///// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// dart2wasmOptions=--enable-deferred-loading

import '' deferred as lib0;
import '' deferred as lib1;

class A {
  void foo() {
    print('A.foo');
  }
}

class B {
  void foo() {
    print('B.foo');
  }
}

class C {
  void foo() {
    print('C.foo');
  }
}

class D {
  void foo() {
    print('D.foo');
  }
}

class E {
  void foo() {
    print('E.foo');
  }
}

class F {
  void foo() {
    print('F.foo');
  }
}

dynamic confuse(dynamic x) {
  return x;
}

Future<void> main() async {
  dynamic a = confuse(A());
  dynamic b = confuse(B());
  confuse(a).foo();
  confuse(b).foo();
  await lib0.loadLibrary();
  dynamic c = confuse(lib0.C());
  dynamic d = confuse(lib0.D());
  confuse(c).foo();
  confuse(d).foo();
  await lib1.loadLibrary();
  dynamic e = confuse(lib1.E());
  dynamic f = confuse(lib1.F());
  confuse(e).foo();
  confuse(f).foo();
}
