// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that a compile-time error is generated when instantiate to
// bound can't be applied due to raw types with non-simple bounds.  The
// non-simplicity in this test is due to having another raw type in the bound
// that in its turn has type variables with non-simple bounds.

class A<TypeT, TypeS extends TypeT> {}

class B<TypeU extends A> {}

class C<TypeV extends B> {}

C c;

main() {}
