// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2js was generating incorrect code for the [A] constructor, by
// using a temporary variable for two instructions, even though they
// are both live at the same time.

import "package:expect/expect.dart";

var globalVar = [1, 2];

class A {
  final field1;
  final field2;
  var field3;

  A(this.field1, this.field2) {
    bool entered = false;
    // We use [field1] twice to ensure it will have a temporary.
    for (var a in field1) {
      try {
        entered = true;
        // We use [field2] twice to ensure it will have a temporary.
        print(field2);
        print(field2);
      } catch (e) {
        // Because the catch is aborting, the SSA graph we used to
        // generate thought that the whole try/catch was aborting, and
        // therefore it could not reach the code after the loop.
        throw e;
      }
    }
    Expect.isTrue(entered);
    // dart2js used to overwrite the temporary for [field1] with
    // [field2].
    Expect.equals(globalVar, field1);
  }
}

main() {
  new A(globalVar, null);
}
