// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import "../library10.dart";

main() {
  // Library prefixes in the imported libraries should not be visible here.
  new lib11.Library11(1);
  //  ^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
  // [cfe] Couldn't find constructor 'lib11.Library11'.
  lib11.Library11.static_func();
  // [error column 3, length 5]
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
  // [cfe] Undefined name 'lib11'.
  lib11.Library11.static_fld;
  // [error column 3, length 5]
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
  // [cfe] Undefined name 'lib11'.
}
