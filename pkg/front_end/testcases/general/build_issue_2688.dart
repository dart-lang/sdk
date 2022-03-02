// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/build/issues/2688

mixin M0 {
  int get property;
}
mixin M1 implements M0 {
  int get property;
}
mixin M2 implements M1 {
  int get property;
}
mixin M3 implements M2 {
  int get property;
}
mixin M4 implements M3 {
  int get property;
}
mixin M5 implements M4 {
  int get property;
}
mixin M6 implements M5 {
  int get property;
}
mixin M7 implements M6 {
  int get property;
}
mixin M8 implements M7 {
  int get property;
}
mixin M9 implements M8 {
  int get property;
}
mixin M10 implements M9 {
  int get property;
}
mixin M11 implements M10 {
  int get property;
}
mixin M12 implements M11 {
  int get property;
}
mixin M13 implements M12 {
  int get property;
}
mixin M14 implements M13 {
  int get property;
}
mixin M15 implements M14 {
  int get property;
}
mixin M16 implements M15 {
  int get property;
}
mixin M17 implements M16 {
  int get property;
}
mixin M18 implements M17 {
  int get property;
}
mixin M19 implements M18 {
  int get property;
}
mixin M20 implements M19 {
  int get property;
}
mixin M21 implements M20 {
  int get property;
}
mixin M22 implements M21 {
  int get property;
}
mixin M23 implements M22 {
  int get property;
}
mixin M24 implements M23 {
  int get property;
}
mixin M25 implements M24 {
  int get property;
}
mixin M26 implements M25 {
  int get property;
}
mixin M27 implements M26 {
  int get property;
}

abstract class Super {
  int get property;
}

class Class extends Super
    with
        M0,
        M1,
        M2,
        M3,
        M4,
        M5,
        M6,
        M7,
        M8,
        M9,
        M10,
        M11,
        M12,
        M13,
        M14,
        M15,
        M16,
        M17,
        M18,
        M19,
        M20,
        M21,
        M22,
        M23,
        M24,
        M25,
        M26,
        M27 {
  int get property => 0;
}

main() {}
