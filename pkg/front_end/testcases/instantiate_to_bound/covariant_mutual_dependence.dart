// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that covariant occurrences of mutually dependent type
// variables in the bounds of all of these type variables are replaced with
// `dynamic`.

class B<X, Y> {}

class C<X, Y> {}

class D<X extends B<X, Y>, Y extends C<X, Y>> {}

D d;

class E<X extends B<X, Y>, Y extends X Function()> {}

E e;

class F<X extends X Function()> {}

F f;

main() {}
