// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.
//
// Test for issue 1393.  Invoking a library prefix name caused an internal error
// in dartc.

import "illegal_invocation_lib.dart" as foo; // //# 01: compile-time error

main() {
  // probably what the user meant was foo.foo(), but the qualifier refers
  // to the library prefix, not the method defined within the library.
  foo(); //                        //# 01: continued
}
