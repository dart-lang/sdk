// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void f1({int _ = 0}) {}
void f2({int _ = 0, String _ = ''}) {}

class C {
  int _;
  C({this._ = 0});
}

test() {
  f1(_: 1);
  f2(_: 2);
  C(_: 3);
}
