// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Type parameters can shadow a library prefix.

import "package:expect/expect.dart";
import "../library10.dart" as T;
import "../library10.dart" as lib10;

class P<T> {
  test() {
    new T.Library10(10);
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.PREFIX_SHADOWED_BY_LOCAL_DECLARATION
    //    ^
    // [cfe] Method not found: 'T.Library10'.
  }
}

main() {
  new P<int>().test();

  {
    // Variables in the local scope hide the library prefix.
    var lib10 = 0;
    var result = 0;
    result = lib10.Library10.static_fld;
    //             ^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'Library10' isn't defined for the class 'int'.
    Expect.equals(4, result);
  }

  {
    // Shadowing is not an error.
    var lib10 = 1;
    Expect.equals(2, lib10 + 1);
  }
}
