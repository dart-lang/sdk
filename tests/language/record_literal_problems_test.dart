// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  var r1 = const (42);
  //                ^
  // [analyzer] SYNTACTIC_ERROR.RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA
  // [cfe] A record literal with exactly one positional field requires a trailing comma.

  var r2 = const ();
}
