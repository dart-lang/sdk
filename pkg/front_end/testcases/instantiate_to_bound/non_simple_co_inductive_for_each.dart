// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that the error is reported for all type variables that
// reference the raw generic type they are defined on.

class A<TypeX extends A, TypeY extends A> {}

typedef C<TypeX extends C, TypeY extends C> = int;

main() {}
