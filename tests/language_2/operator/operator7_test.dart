// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// No "===" operator.

class C {
  operator ===(int index) {
  //       ^
  // [analyzer] SYNTACTIC_ERROR.UNSUPPORTED_OPERATOR
  // [cfe] The '===' operator is not supported.
    return index;
  }
}

main() {
  C();
}
