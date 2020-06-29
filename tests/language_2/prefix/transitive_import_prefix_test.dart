// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import "../library10.dart";

main() {
  // Library prefixes in the imported libraries should not be visible here.
  new lib11.Library11(1);
  //  ^^^^^^^^^^^^^^^
  // [analyzer] STATIC_WARNING.CREATION_WITH_NON_TYPE
  // [cfe] Method not found: 'lib11.Library11'.
  lib11.Library11.static_func();
//^^^^^
// [analyzer] STATIC_WARNING.UNDEFINED_IDENTIFIER
// [cfe] Getter not found: 'lib11'.
  lib11.Library11.static_fld;
//^^^^^
// [analyzer] STATIC_WARNING.UNDEFINED_IDENTIFIER
// [cfe] Getter not found: 'lib11'.
}
