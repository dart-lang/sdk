// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that conditional expression can be a compile-time constant.

import "package:expect/expect.dart";

const C1 = true;
const C2 = false;

const nephew = C1 ? C2 ? "Tick" : "Trick" : "Track";

main() {
  const a = true ? 5 : 10;
  const b = C2 ? "Track" : C1 ? "Trick" : "Tick";

  Expect.equals(5, a);
  Expect.equals("Trick", nephew);
  Expect.equals(nephew, b);
  Expect.identical(nephew, b);
  var s = const Symbol(nephew);
  var msg = "Donald is $nephew's uncle.";
  Expect.equals("Donald is Trick's uncle.", msg);
}
