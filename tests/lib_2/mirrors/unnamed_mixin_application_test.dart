// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that the forwarding constructors of unnamed mixin applications are
/// included for reflection.

library lib;

@MirrorsUsed(targets: "lib")
import 'dart:mirrors';

class S {
  S();
  S.anUnusedName();
}

class M {}

class C extends S with M {
  C();
}

main() {
  // Use 'C#', 'S+M#' and 'S#' but not 'S#anUnusedName' nor 'S+M#anUnusedName'.
  new C();
  // Disable tree shaking making 'S+M#anUnusedName' live.
  reflectClass(C);
}
