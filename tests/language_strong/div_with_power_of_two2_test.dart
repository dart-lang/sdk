// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test division by power of two.
// Test that results before and after optimization are the same.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr

import "package:expect/expect.dart";

// [function, [list of tuples argument/result]].
var expectedResults = [
  [
    divBy1,
    [
      [134217730, 134217730],
      [-134217730, -134217730],
      [10, 10],
      [-10, -10]
    ]
  ],
  [
    divByNeg1,
    [
      [134217730, -134217730],
      [-134217730, 134217730],
      [10, -10],
      [-10, 10]
    ]
  ],
  [
    divBy2,
    [
      [134217730, 67108865],
      [-134217730, -67108865],
      [10, 5],
      [-10, -5]
    ]
  ],
  [
    divByNeg2,
    [
      [134217730, -67108865],
      [-134217730, 67108865],
      [10, -5],
      [-10, 5]
    ]
  ],
  [
    divBy4,
    [
      [134217730, 33554432],
      [-134217730, -33554432],
      [10, 2],
      [-10, -2]
    ]
  ],
  [
    divByNeg4,
    [
      [134217730, -33554432],
      [-134217730, 33554432],
      [10, -2],
      [-10, 2]
    ]
  ],
  [
    divBy134217728,
    [
      [134217730, 1],
      [-134217730, -1],
      [10, 0],
      [-10, 0]
    ]
  ],
  [
    divByNeg134217728,
    [
      [134217730, -1],
      [-134217730, 1],
      [10, 0],
      [-10, 0]
    ]
  ],
  // Use different functions for 64 bit arguments.
  [
    divBy4_,
    [
      [549755813990, 137438953497],
      [-549755813990, -137438953497],
      [288230925907525632, 72057731476881408],
      [-288230925907525632, -72057731476881408]
    ]
  ],
  [
    divByNeg4_,
    [
      [549755813990, -137438953497],
      [-549755813990, 137438953497],
      [288230925907525632, -72057731476881408],
      [-288230925907525632, 72057731476881408]
    ]
  ],
  [
    divBy549755813888,
    [
      [549755813990, 1],
      [-549755813990, -1],
      [288230925907525632, 524289],
      [-288230925907525632, -524289]
    ]
  ],
  [
    divByNeg549755813888,
    [
      [549755813990, -1],
      [-549755813990, 1],
      [288230925907525632, -524289],
      [-288230925907525632, 524289]
    ]
  ],
];

divBy0(a) => a ~/ 0;
divBy1(a) => a ~/ 1;
divByNeg1(a) => a ~/ -1;
divBy2(a) => a ~/ 2;
divByNeg2(a) => a ~/ -2;
divBy4(a) => a ~/ 4;
divByNeg4(a) => a ~/ -4;
divBy134217728(a) => a ~/ 134217728;
divByNeg134217728(a) => a ~/ -134217728;

divBy4_(a) => a ~/ 4;
divByNeg4_(a) => a ~/ -4;
divBy549755813888(a) => a ~/ 549755813888;
divByNeg549755813888(a) => a ~/ -549755813888;

main() {
  for (int i = 0; i < 20; i++) {
    for (var e in expectedResults) {
      Function f = e[0];
      List values = e[1];
      for (var v in values) {
        int arg = v[0];
        int res = v[1];
        Expect.equals(res, f(arg));
      }
    }
    Expect.throws(() => divBy0(4),
        (e) => e is IntegerDivisionByZeroException || e is UnsupportedError);
  }
}
