// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that an intercepted call on a method that does not exist does
// not crash the compiler.

import "package:expect/expect.dart";

main() {
  Expect.throws(() => 42.clamp(), (e) => e is NoSuchMethodError);
}
