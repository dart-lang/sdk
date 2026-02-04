// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that the correct number of type arguments is observed in the
// Invocation object for invocations that pass all-dynamic type arguments.

import "package:expect/expect.dart";

class C {
  dynamic noSuchMethod(Invocation invoke) {
    Expect.equals(1, invoke.typeArguments.length);
  }
}

void main() {
  ((new C()) as dynamic).foo<dynamic>();
}
