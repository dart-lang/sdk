// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=single-combinators

import "package:expect/expect.dart";

import "show_lib.dart";
import "hide_lib.dart" as hide_p;

main() {
  Expect.equals(1, a);
  Expect.type<A>(A());

  Expect.equals(2, hide_p.b);
  Expect.equals(3, hide_p.c);
  Expect.type<hide_p.B>(hide_p.B());
  Expect.type<hide_p.C>(hide_p.C());
}
