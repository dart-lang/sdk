// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test for a function with a malformed result type.

import "package:expect/expect.dart";

class C<T, U> {}

main() {
  C<int> f() => null; //# 00: compile-time error
}
