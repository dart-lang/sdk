// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that compiler doesn't crash after inlining a function
// with number of SSA values allocated for constants in the parameter stubs
// greater then number of SSA values in the caller graph.
// Regression test for https://github.com/flutter/flutter/issues/119220.

import 'package:expect/expect.dart';

@pragma('vm:prefer-inline')
List<int> badFunction(int v,
    [int a0 = 0,
    int a1 = 1,
    int a2 = 2,
    int a3 = 3,
    int a4 = 4,
    int a5 = 5,
    int a6 = 6,
    int a7 = 7,
    int a8 = 8,
    int a9 = 9,
    int a10 = 10,
    int a11 = 11,
    int a12 = 12,
    int a13 = 13,
    int a14 = 14,
    int a15 = 15,
    int a16 = 16,
    int a17 = 17,
    int a18 = 18,
    int a19 = 19,
    int a20 = 20,
    int a21 = 21,
    int a22 = 22,
    int a23 = 23]) {
  return [
    a0,
    a1,
    a2,
    a3,
    a4,
    a5,
    a6,
    a7,
    a8,
    a9,
    a10,
    a11,
    a12,
    a13,
    a14,
    a15,
    a16,
    a17,
    a18,
    a19,
    a20,
    a21,
    a22,
    a23,
  ];
}

// When inlining [badFunction] into this function `AdjustForOptionalParameters`
// will create a constant value in the callee graph for each missing parameter.
// If we don't take these constant values into account when numbering SSA
// values later in ComputeSSA we will: (a) temporary end up with
// multiple definitions sharing the same SSA temp index (b) with SSA temp index
// these constants potentially exceeding callee's graph max SSA temp index.
// These violations will cause compiler passes that rely on SSA indices for
// to break in various ways.
@pragma('vm:never-inline')
List<int> badFunction2() => badFunction(0);

@pragma('vm:never-inline')
List<int> badFunction3() => badFunction(88, 88, 88, 88, 88, 88, 88, 88, 88, 88,
    88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88, 88);

void main() {
  Expect.listEquals(<int>[
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23
  ], badFunction2());
  Expect.listEquals(<int>[
    88,
    88,
    88,
    88,
    88,
    88,
    88,
    88,
    88,
    88,
    88,
    88,
    88,
    88,
    88,
    88,
    88,
    88,
    88,
    88,
    88,
    88,
    88,
    88
  ], badFunction3());
}
