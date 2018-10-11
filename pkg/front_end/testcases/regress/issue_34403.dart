// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'issue_34403_lib.dart' as p;

class C<T> {
  C.bar();
}

class D<T> {
  const D.foo();
}

main() {
  var c1 = C.bar<int>();
  c1.toString();
  var c2 = new C.bar<int>();
  c2.toString();
  var c3 = C<String>.bar<int>();
  c3.toString();
  var c4 = new C<String>.bar<int>();
  c4.toString();

  const d1 = D.foo<int>();
  d1.toString();
  const d2 = const D.foo<int>();
  d2.toString();
  const d3 = D<String>.foo<int>();
  d3.toString();
  const d4 = const D<String>.foo<int>();
  d4.toString();

  var e1 = p.E.bar<int>();
  e1.toString();
  var e2 = new p.E.bar<int>();
  e2.toString();
  var e3 = p.E<String>.bar<int>();
  e3.toString();
  var e4 = new p.E<String>.bar<int>();
  e4.toString();

  const f1 = p.F.foo<int>();
  f1.toString();
  const f2 = const p.F.foo<int>();
  f2.toString();
  const f3 = p.F<String>.foo<int>();
  f3.toString();
  const f4 = const p.F<String>.foo<int>();
  f4.toString();
}
