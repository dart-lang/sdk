// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Key {
  int get a => runtimeType.hashCode xor null.hashCode;
  int get b => runtimeType.hashCode ^ null.hashCode;
  int get c { return runtimeType.hashCode xor null.hashCode; }
  int get d { return runtimeType.hashCode ^ null.hashCode; }

  int get e => 1 + runtimeType.hashCode xor null.hashCode + 3;
  int get f => 1 + runtimeType.hashCode ^ null.hashCode + 3;
  int get g { return 1 + runtimeType.hashCode xor null.hashCode + 3; }
  int get h { return 1 + runtimeType.hashCode ^ null.hashCode + 3; }

  int i(int x, int y) => x xor y;
  int j(int x, int y) => x ^ y;
  int k(int x, int y) { return x xor y; }
  int l(int x, int y) { return x ^ y; }
  int m(int x, int y) { int z =  x xor y; return z; }
  int n(int x, int y) { int z = x ^ y; return z; }

  int o(int x, int y) => 1 + x xor y + 3;
  int p(int x, int y) => 1 + x ^ y + 3;
  int q(int x, int y) { return 1 + x xor y + 3; }
  int r(int x, int y) { return 1 + x ^ y + 3; }

  s(int x, int y) {
    s(x xor y, x xor y);
    s(x ^ y, x ^ y);
  }

  int foo;
  int bar;

  Key(int x, int y) : foo = x xor y, bar = x xor y {
    print("hello ${x xor y}");
  }

  Key.NotDuplicate(int x, int y) : foo = x ^ y, bar = x ^ y {
    print("hello ${x ^ y}");
  }
}

main() {}