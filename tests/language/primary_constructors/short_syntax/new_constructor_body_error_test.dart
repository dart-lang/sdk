// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// We emit an error if a const constructor has a body, even with the new,
// shorter syntax.

class C {
  final int x;
  const new(this.x) {}
  // [error column 3]
  // [cfe] A const constructor can't have a body.
  //                ^
  // [analyzer] SYNTACTIC_ERROR.CONST_CONSTRUCTOR_WITH_BODY

  const new named(this.x) {}
  // [error column 3]
  // [cfe] A const constructor can't have a body.
  //                      ^
  // [analyzer] SYNTACTIC_ERROR.CONST_CONSTRUCTOR_WITH_BODY
}
