// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that the error message is not duplicated in case when the
// raw generic type is used more than once in the bound of its own type
// variable.

class A<TypeX extends Map<A, A>> {}

typedef C<TypeX extends Map<C, C>> = int;

main() {}
