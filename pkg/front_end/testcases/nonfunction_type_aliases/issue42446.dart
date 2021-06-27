// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X extends A<X>> {}
typedef B<X extends A<X>> = A<X>;

class A2<X extends A2<X>> {
  factory A2() => throw 42;
}
typedef B2<X extends A2<X>> = A2<X>;

foo() {
  B(); // Error.
  A(); // Error.
  B2(); // Error.
  A2(); // Error.
}

main() {}
