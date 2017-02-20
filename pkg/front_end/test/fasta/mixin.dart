// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class B extends Object with M1, M2 {
  B(value);
}

abstract class M1 {
  m() => print("M1");
}

abstract class M2 {
  m() => print("M2");
}

class C extends Object with M1, M2 {
  C(value);
}

abstract class G1<T> {
  m() => print(T);
}

class D<S> extends Object with G1<S> {
}

main() {
  new B(null).m();
  new C(null).m();
  new D().m();
  new D<int>().m();
  new D<List<int>>().m();
}
