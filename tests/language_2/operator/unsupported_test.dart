// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test handling of unsupported operators.

library unsupported_operators;

class C {
  m() {
    print(
          super ===
          //    ^
          // [analyzer] SYNTACTIC_ERROR.UNSUPPORTED_OPERATOR
          // [cfe] The '===' operator is not supported.
          //    ^
          // [cfe] The string '===' isn't a user-definable operator.
        null);
    print(
          super !==
          //    ^
          // [analyzer] SYNTACTIC_ERROR.UNSUPPORTED_OPERATOR
          // [cfe] The '!==' operator is not supported.
          //    ^
          // [cfe] The string '!==' isn't a user-definable operator.
        null);
  }
}

void main() {
  new C().m();
  new C().m();
  print(
        "foo" ===
        //    ^
        // [analyzer] SYNTACTIC_ERROR.UNSUPPORTED_OPERATOR
        // [cfe] The '===' operator is not supported.
        //    ^
        // [cfe] The string '===' isn't a user-definable operator.
      null);
  print(
        "foo" !==
        //    ^
        // [analyzer] SYNTACTIC_ERROR.UNSUPPORTED_OPERATOR
        // [cfe] The '!==' operator is not supported.
        //    ^
        // [cfe] The string '!==' isn't a user-definable operator.
      null);
}
