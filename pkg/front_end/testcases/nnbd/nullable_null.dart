// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The test checks that Null is nullable.

class A<X> {}

class B extends A<Null> {}

class C {
  Null foo(Null n, A<Null> an) => n;
}

foo() {
  return [<Null>[], <A<Null>>[]];
}

bar() {
  return [const <Null>[], const <A<Null>>[]];
}

main() {}
