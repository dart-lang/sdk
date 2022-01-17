// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class S1 {
  int s1;
  int s2;
  S1(this.s1, [this.s2 = 42]);
}

class C1 extends S1 {
  int i1;
  int i2;
  C1(this.i1, super.s1, int x, [super.s2]) : this.i2 = x;
}

class S2 {
  S2({String one = "1", bool two = false, int three = 3, double four = 4,
      num five = 3.14, List<String> six = const ["six"]});
}

class C21 extends S2 {
  C21({dynamic foo, super.one, dynamic bar, dynamic baz, super.three,
      super.five});
}

class C22 extends S2 {
  C22({dynamic foo, super.six, dynamic bar, dynamic baz, super.four,
      super.two});
}

class C23 extends S2 {
  C23({super.three, dynamic foo, super.one, super.four, dynamic bar, super.two,
      dynamic baz});
}

main() {}
