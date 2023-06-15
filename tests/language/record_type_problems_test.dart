// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  (int, int, {/*missing*/}) r1 = (1, 2);
  //                     ^
  // [analyzer] SYNTACTIC_ERROR.EMPTY_RECORD_TYPE_NAMED_FIELDS_LIST
  // [cfe] The list of named fields in a record type can't be empty.

  (int /* missing trailing comma */ ) r2 = (1, );
  //                                ^
  // [analyzer] SYNTACTIC_ERROR.RECORD_TYPE_ONE_POSITIONAL_NO_TRAILING_COMMA
  // [cfe] A record type with exactly one positional field requires a trailing comma.
}
