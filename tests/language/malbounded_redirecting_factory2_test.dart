// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<
    Ta
           extends num // //# 02: continued
    > implements B<Ta>, C<Ta> {}

class B<
    Tb
           extends num // //# 03: continued
    > {
  factory B() = A<Tb>;
}

class C<
    Tc
           extends num // //# 04: continued
    > {
  factory C() = B<Tc>;
}

class D<Td> {
  test() => new C<Td>();
}

main() {
  new D<int>().test();
  new D<String>().test(); // //# 01: static type warning
  new D<String>().test(); // //# 02: static type warning, dynamic type error
  new D<String>().test(); // //# 03: static type warning, dynamic type error
  new D<String>().test(); // //# 04: static type warning, dynamic type error
}
