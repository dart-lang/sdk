// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Symbols in libraries imported by the prefixed library should not be visible.

import "../library12.dart" as lib12;

main() {
  // Class should not be visible.
  new lib12.Library11(1);
  //        ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CREATION_WITH_NON_TYPE
  // [cfe] Couldn't find constructor 'Library11'.

  // Variable should not be visible.
  lib12.top_level11;
  //    ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_PREFIXED_NAME
  // [cfe] Undefined name 'top_level11'.
}
