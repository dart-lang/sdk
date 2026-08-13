// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that the error message is not duplicated in the case when
// the same raw generic type with non-simple bounds is used in the bound of a
// type variable.

class A<TypeX extends A<TypeX>> {}

class B<TypeY extends Map<A, A>> {}

extension C<TypeY extends Map<A, A>> on int {}

typedef D<TypeY extends Map<A, A>> = int;

main() {}
