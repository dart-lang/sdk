// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  const C({dynamic x = const A.foo()});
}

class B<X> extends A {
  const B();
}

abstract class A {
  const A();
  const factory A.foo() = B;
}

main() {}
