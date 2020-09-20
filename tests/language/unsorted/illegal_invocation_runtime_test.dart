// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.
//
// Test for issue 1393.  Invoking a library prefix name caused an internal error
// in dartc.



main() {
  // probably what the user meant was foo.foo(), but the qualifier refers
  // to the library prefix, not the method defined within the library.

}
