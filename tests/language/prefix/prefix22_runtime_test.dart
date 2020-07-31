// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Unresolved symbols should be reported as static type warnings.
// This should not prevent execution.

library Prefix21NegativeTest.dart;
import "../library12.dart" as lib12;

class myClass {
  myClass(

      p) { }
}

main() {
  new myClass(null);  // no dynamic type error when assigning null
}
