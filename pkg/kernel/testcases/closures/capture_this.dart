// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class C {
  var x;
  m() => (v) => x = v;
  f() => () => () => x;
}

main() {
  C c = new C();
  c.x = 41;
  c.m()(42);
  if (42 != c.x) throw "Unexpected value in c.x: ${c.x}";
  var result = c.f()()();
  if (42 != result) throw "Unexpected value from c.f()()(): $result";
}
