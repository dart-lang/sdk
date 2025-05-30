// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Formatting can break multitests, so don't format them.
// dart format off

import "package:expect/expect.dart";

abstract class I {}

void main() {
  var list;
  list = <
      int
    I //# 00: syntax error
    , int //# 01: compile-time error
      >[0];
  Expect.equals(1, list.length);

  list = <
      int
    , int //# 02: compile-time error
    , int //# 02: continued
      >[0];
  Expect.equals(1, list.length);

  list = <
      int
    , int //# 03: compile-time error
    , int //# 03: continued
    , int //# 03: continued
      >[0];
  Expect.equals(1, list.length);

  list =
    <> //# 04: syntax error
      [0];
  Expect.equals(1, list.length);

  list =
    <<>> //# 05: syntax error
      [0];
  Expect.equals(1, list.length);

  list =
    <<<>>> //# 06: syntax error
      [0];
  Expect.equals(1, list.length);

  list =
    <[]> //# 07: syntax error
      [0];
  Expect.equals(1, list.length);

  list = <int>[
    <int>[
      <int>[1][0]
    ][0]
  ];
  Expect.equals(1, list.length);
  Expect.equals(1, list[0]);

  list = <int>[
    <List<int>>[
      [1]
    ][0][0]
  ];
  Expect.equals(1, list.length);
  Expect.equals(1, list[0]);
}
