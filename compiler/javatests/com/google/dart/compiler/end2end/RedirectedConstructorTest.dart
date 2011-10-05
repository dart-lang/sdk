// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  var x;
  A(this.x) {}
  A.named1(x, y) : this(x + y);
  A.named2(x, y, z) : this.named1(x + y, z);
}

class B extends A {
  B(y) : super.named2(y, y + 1, y + 2) { }
  B.named(x) : this(x);
}

main() {
  var a1 = new A.named1(1, 2);
  assert(a1.x == 3);

  var a2 = new A.named2(1, 2, 3);
  assert( a2.x == 6);
    
  var b = new B.named(-1);
  assert(b.x == 0);
}
