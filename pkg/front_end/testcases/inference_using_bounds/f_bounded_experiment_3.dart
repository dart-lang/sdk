// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X extends A<X, Y>, Y> {}
class B extends A<B, String> {}
class C extends B {}

foo<T extends A<T, S>, S>(T t) {}

main() {
  foo(new C());
}
