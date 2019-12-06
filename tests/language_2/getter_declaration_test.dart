// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that a getter takes no parameters.
get m(extraParam) {
//   ^
// [analyzer] SYNTACTIC_ERROR.GETTER_WITH_PARAMETERS
// [cfe] A getter can't have formal parameters.
  return null;
}

main() {
  m;
}
