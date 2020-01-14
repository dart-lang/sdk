// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

abstract class B {
  int get x;
}

class C {
  int get x => 42;
}

class D extends C with B {
  final int x;

  D(this.x);
}

class C2 {
  int get x => 42;
}

abstract class B2 extends C2 {
  int get x;
}

class D2 extends B2 {
  final int x;

  D2(this.x);
}

void main() {
  var d = new D(17);
  Expect.equals(d.x, 17);

  var d2 = new D2(17);
  Expect.equals(d.x, 17);
}
