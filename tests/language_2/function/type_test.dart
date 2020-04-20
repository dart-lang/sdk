// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test for a function type test that cannot be eliminated at compile time.
import "package:expect/expect.dart";

typedef FListInt(List<int> l);

main() {
  Expect.throwsTypeError(() {
    // Static result type of f(), i.e. FList, is a subtype of FListInt.
    // However, run time type of returned function is not a subtype of FListInt.
    // Run time type check should not be eliminated.
    FListInt fli = ((List<String> l) => null) as dynamic;
  });
}
