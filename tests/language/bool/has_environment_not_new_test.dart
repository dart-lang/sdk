// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

const bool isVM = const bool.fromEnvironment('dart.isVM');

main() {
  // On non-VM targets `new bool.hasEnvironment(...)` just throws, because it
  // is only guaranteed to work with `const`. However on VM it actually works.
  if (!isVM) {
    Expect.throws(() => new bool.hasEnvironment("Anything"));
  } else {
    Expect.isFalse(new bool.hasEnvironment("Anything"));
  }
}
