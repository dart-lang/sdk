// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<X> {
  C();
  factory C.foo() => new C();
}

typedef A<X extends C<X>> = C<X>;

foo() {
  A();
  A.foo();
}

main() {}
