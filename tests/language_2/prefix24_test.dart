// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library prefix24_test;

import "package:expect/expect.dart";

// Import a library that contains library prefix X.
import "prefix24_lib1.dart";

// Import a library that declares class X.
import "prefix24_lib3.dart";

// Check that the library prefix X that is used in library prefix24_lib1
// remains private to that library and does not collide with class X
// defined in (and imported from) prefix24_lib3;

main() {
  Expect.equals("static method bar of class X", X.bar());
  Expect.equals("prefix24_lib2_bar", lib1_foo());
}
