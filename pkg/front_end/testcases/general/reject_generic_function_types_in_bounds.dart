// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that generic function types are rejected with an appropriate
// compile-time error message if encountered in bounds of type variables.

class Hest<TypeX extends TypeY Function<TypeY>(TypeY)> {}

main() {}
