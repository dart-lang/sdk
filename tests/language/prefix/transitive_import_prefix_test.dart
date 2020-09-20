// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import "../library10.dart";

main() {
  // Library prefixes in the imported libraries should not be visible here.
  new lib11.Library11(1);
  //  ^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CREATION_WITH_NON_TYPE
  // [cfe] Method not found: 'lib11.Library11'.
  lib11.Library11.static_func();
//^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
// [cfe] Getter not found: 'lib11'.
  lib11.Library11.static_fld;
//^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
// [cfe] Getter not found: 'lib11'.
}
