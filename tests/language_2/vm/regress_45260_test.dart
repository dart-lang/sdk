// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// VMOptions=--optimization-counter-threshold=5 --deterministic

import 'package:expect/expect.dart';

List<List<List<List<int>>>> toNestedList() {
  final list = [
    for (var i0 = 0; i0 < 2; i0++)
      [
        for (var i1 = 0; i1 < 2; i1++)
          [
            for (var i2 = 0; i2 < 2; i2++)
              [
                for (var i3 = 0; i3 < 2; i3++)
                  1000 * i0 + 100 * i1 + 10 * i2 + i3
              ]
          ]
      ]
  ];
  return list;
}

const expectedList = [
  [
    [
      [0000, 0001],
      [0010, 0011],
    ],
    [
      [0100, 0101],
      [0110, 0111],
    ]
  ],
  [
    [
      [1000, 1001],
      [1010, 1011],
    ],
    [
      [1100, 1101],
      [1110, 1111],
    ]
  ]
];

void main() {
  Expect.deepEquals(expectedList, toNestedList());
}
