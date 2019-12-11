// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--reify-generic-functions

import "package:expect/expect.dart";

T foo<T>(T i) => i;

void main() {
  Expect.equals(42, foo<int>(42));

  var bar = foo;
  Expect.equals(42, bar<int>(42));

  // Generic function types are not allowed as type arguments.


  // Type inference must also give an error.


  // No error if illegal type cannot be inferred.


}
