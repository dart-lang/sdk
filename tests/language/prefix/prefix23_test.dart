// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Unresolved symbols should be reported as an static type warnings.
// This should not prevent execution.

library Prefix23Test.dart;

import "../library12.dart" as lib12;

class myClass {
  final
      lib12.Library13
//    ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_CLASS
// [cfe] Type 'lib12.Library13' not found.
//          ^
// [cfe] 'Library13' isn't a type.
      fld = null;
}

main() {}
