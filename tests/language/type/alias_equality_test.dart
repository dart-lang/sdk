// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that type aliases perform equality tests according to the
// underlying function type, not as if they were a distinct type
// for each type alias declaration.

import 'package:expect/expect.dart';

typedef F1 = void Function(int);
typedef F2 = void Function(int);
typedef void F3(int x);

typedef G1 = X Function<X>(X);
typedef G2 = X Function<X>(X);
typedef G3 = Y Function<Y>(Y);

main() {
  Expect.equals(F1, F2); //# 01: ok
  Expect.equals(F1, F3); //# 02: ok
  Expect.equals(G1, G2); //# 03: ok
  Expect.equals(G1, G3); //# 04: ok
}
