// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that an attempt to use a raw generic type with non-simple
// bounds is detected and reported as a compile-time error in case the
// non-simple bound is due to the use of the type variable from the same
// declaration.

class Hest<TypeX extends Hest<TypeX>> {}

class Fisk<TypeY extends Hest> {}

main() {}
