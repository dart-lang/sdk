// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  f(B());
}

f(A a) {
  switch (a) {
    case B():
      print("It's a B");
  }
}

class B extends A with M {
  B();
}

sealed class A {}

mixin M {}
