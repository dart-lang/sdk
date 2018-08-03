// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that covariant occurrences of a type variable in the bounds
// of the other type variables from the same declaration that are not being
// transitively depended on by that type variable are replaced with the bound of
// that type variable.

class A<X> {}

class C<X, Y extends A<X>> {}

C c;

class D<X extends num, Y extends A<X>> {}

D d;

class E<X, Y extends X Function()> {}

E e;

class F<X extends num, Y extends X Function()> {}

F f;

main() {}
