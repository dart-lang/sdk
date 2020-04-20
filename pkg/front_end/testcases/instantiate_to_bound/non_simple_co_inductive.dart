// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that the use of a raw generic type in the bounds of its own
// type variables is recognized and reported as a compile-time error.

class Hest<TypeX extends Hest> {}

main() {}
