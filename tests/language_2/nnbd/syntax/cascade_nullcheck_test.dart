// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

import "package:expect/expect.dart";

class C {
  int? y;
  D? f() => new D();
  C? h() => this;
}

class D {
  D g() => this;
  bool? operator [](String s) => true;
}

void test(C x) {
  x..f()!.g()['Hi!']!..h()!.y = 2;
}

main() {
  test(new C());
}
