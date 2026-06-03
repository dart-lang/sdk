// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int f() => 5;

class A {
  final int x;
  A.n1() : x = 42.{
    return this;
  };
  A.n2() : x = 'abc'.{
    return this.length;
  };
  A.n3() : x = f.{
    return this();
  };
  A.n4() : x = 'def'.{
    return this.toString().length;
  };
}

void main() {
  A.n1();
  A.n2();
  A.n3();
  A.n4();
}
