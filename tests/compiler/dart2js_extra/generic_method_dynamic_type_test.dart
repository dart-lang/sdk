// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

class C<CT> {
  foo<FT extends CT>() => CT;

  BT bar<BT extends CT>(BT x) => x;
  CT map<MT extends CT>(MT x) => x;
}

main() {
  dynamic o = new C<num>();

  Expect.equals('<T1 extends num>() => dynamic', o.foo.runtimeType.toString());

  // Instantiations
  int Function(int) f1 = new C<num>().bar;
  num Function(int) f2 = new C<num>().map;

  Expect.equals('(int) => int', f1.runtimeType.toString());
  Expect.equals('(int) => num', f2.runtimeType.toString());
}
