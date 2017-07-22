// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

enum Enum1 { _ }
enum Enum2 { A }
enum Enum3 { B, C }
enum Enum4 {
  D,
  E,
}
enum Enum5 { F, G, H }

main() {
  Expect.equals('Enum1._', Enum1._.toString());
  Expect.equals(0, Enum1._.index);
  Expect.listEquals([Enum1._], Enum1.values);
  Enum1.values.forEach(test1);

  Expect.equals('Enum2.A', Enum2.A.toString());
  Expect.equals(0, Enum2.A.index);
  Expect.listEquals([Enum2.A], Enum2.values);
  Enum2.values.forEach(test2);

  Expect.equals('Enum3.B', Enum3.B.toString());
  Expect.equals('Enum3.C', Enum3.C.toString());
  Expect.equals(0, Enum3.B.index);
  Expect.equals(1, Enum3.C.index);
  Expect.listEquals([Enum3.B, Enum3.C], Enum3.values);
  Enum3.values.forEach(test3);

  Expect.equals('Enum4.D', Enum4.D.toString());
  Expect.equals('Enum4.E', Enum4.E.toString());
  Expect.equals(0, Enum4.D.index);
  Expect.equals(1, Enum4.E.index);
  Expect.listEquals([Enum4.D, Enum4.E], Enum4.values);
  Enum4.values.forEach(test4);

  Expect.equals('Enum5.F', Enum5.F.toString());
  Expect.equals('Enum5.G', Enum5.G.toString());
  Expect.equals('Enum5.H', Enum5.H.toString());
  Expect.equals(0, Enum5.F.index);
  Expect.equals(1, Enum5.G.index);
  Expect.equals(2, Enum5.H.index);
  Expect.listEquals([Enum5.F, Enum5.G, Enum5.H], Enum5.values);
  Enum5.values.forEach(test5);
}

test1(Enum1 e) {
  int index;
  switch (e) {
    case Enum1._:
      index = 0;
      break;
  }
  Expect.equals(e.index, index);
}

test2(Enum2 e) {
  int index;
  switch (e) {
    case Enum2.A:
      index = 0;
      break;
  }
  Expect.equals(e.index, index);
}

test3(Enum3 e) {
  int index;
  switch (e) {
    case Enum3.C:
      index = 1;
      break;
    case Enum3.B:
      index = 0;
      break;
  }
  Expect.equals(e.index, index);
}

test4(Enum4 e) {
  int index;
  switch (e) {
    case Enum4.D:
      index = 0;
      break;
    case Enum4.E:
      index = 1;
      break;
  }
  Expect.equals(e.index, index);
}

test5(Enum5 e) {
  int index;
  switch (e) {
    case Enum5.H:
      index = 2;
      break;
    case Enum5.F:
      index = 0;
      break;
    case Enum5.G:
      index = 1;
      break;
  }
  Expect.equals(e.index, index);
}
