// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that an error is reported on all raw generic types with
// non-simple bounds used in the bound of the same type variable.

class A<TypeX extends A<TypeX>> {}

class B<TypeY extends B<TypeY>> {}

class C<TypeZ extends Map<A, B>> {}

extension D<TypeZ extends Map<A, B>> on int {}

typedef E<TypeZ extends Map<A, B>> = int;

main() {}
