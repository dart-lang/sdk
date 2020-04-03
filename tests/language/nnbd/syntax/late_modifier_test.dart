// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable
import 'package:expect/expect.dart';

late final int d = d_init();
int d_init() => 5;

class C {
  static late final int e = e_init();
  static int e_init() => 6;

  late final int f;
  C() { f = 7; }

  int get g {
    late final int x;
    x = 8;
    return x;
  }
}

main() {
  Expect.equals(d, 5);
  Expect.equals(C.e, 6);
  Expect.equals(C().f, 7);
  Expect.equals(C().g, 8);
}
