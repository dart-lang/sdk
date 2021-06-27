// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


import 'package:expect/expect.dart';

typedef TB<T extends C> = T;
typedef AC = C;  // Direct.
typedef AEC = TB<C>;  // Explicit C argument.
typedef AIC = TB;  // Implicit instantiate to bounds.

class C {
  static const c = 42;
  static int s = 42;
  final int y;
  const C(this.y);
  const C.name(this.y);
}

main() {
  const c0 = AC.c;
  const c1 = AEC.c;
  const c2 = AIC.c;
  Expect.equals(42, AC.s);
  Expect.equals(42, AEC.s);
  Expect.equals(42, AIC.s);
  Expect.equals(0, AC(0).y);
  Expect.equals(0, AEC(0).y);
  Expect.equals(0, AIC(0).y);
  Expect.equals(0, AC.name(0).y);
  Expect.equals(0, AEC.name(0).y);
  Expect.equals(0, AIC.name(0).y);
}
