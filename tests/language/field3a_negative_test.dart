// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test to catch error reporting bugs in class fields declarations.

import "package:expect/expect.dart";

class C {
  final a; // illegal field declaration - must be initialized
}

main() {
  var val = new C();
  Expect.equals(val.a, 0);
}
