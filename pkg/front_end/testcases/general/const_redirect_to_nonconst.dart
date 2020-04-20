// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  const A() : this.bad();

  A.bad() {}
}

class B extends A {
  const B() : super.bad();
}

test() {
  print(const A());
  print(const B());
}

main() {
  print(new A());
  print(new B());
}
