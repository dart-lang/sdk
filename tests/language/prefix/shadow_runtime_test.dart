// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Type parameters can shadow a library prefix.

import "package:expect/expect.dart";
import "../library10.dart" as T;
import "../library10.dart" as lib10;

class P<T> {
  test() {

  }
}

main() {
  new P<int>().test();

  {
    // Variables in the local scope hide the library prefix.

    var result = 0;
    result = lib10.Library10.static_fld;
    Expect.equals(4, result);
  }

  {
    // Shadowing is not an error.
    var lib10 = 1;
    Expect.equals(2, lib10 + 1);
  }
}
