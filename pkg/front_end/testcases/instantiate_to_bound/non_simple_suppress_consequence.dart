// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that in the case of an error on a class related to
// non-simple bounds, the implied errors on other classes that reference the
// erroneous one in the bounds of their type variables is not reported.

class A<TypeX extends A<TypeX>> {}

class B<TypeY extends A> {}

class C<TypeZ extends B> {}

extension D<TypeY extends A> on int {}

extension E<TypeZ extends B> on int {}

typedef F<TypeY extends A> = int;

typedef G<TypeZ extends B> = int;

main() {}
