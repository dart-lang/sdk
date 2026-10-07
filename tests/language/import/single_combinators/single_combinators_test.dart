// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=single-combinators

import "package:expect/expect.dart";

import "import_helper.dart" show a, A;
import "import_helper.dart" as p hide a, A;

main() {
  Expect.equals(1, a);
  Expect.type<A>(A());

  Expect.equals(2, p.b);
  Expect.equals(3, p.c);
  Expect.type<p.B>(p.B());
  Expect.type<p.C>(p.C());
}
