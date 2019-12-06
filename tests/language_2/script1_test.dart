// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Wrong order of import and part directives.

part "script1_part.dart";
import "script1_lib.dart";
// [error line 8, column 1, length 6]
// [analyzer] SYNTACTIC_ERROR.IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE
// [cfe] Import directives must precede part directives.

main() {
  print("Should not reach here.");
}
