// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const List<int> intList = <int>[0, 1, 2];
const List<(int, int)> intIntList = <(int, int)>[(0, 1), (2, 3)];

test() {
  const <num>[
    for (int i = 0; i < intList.length; i++) intList[i], // Error
    for (var (i, j) = (0, 1); i < intList.length; i++) intList[i] + j, // Error
    for (var e in intList) e, // Error
    for (var (a, b) in intIntList) a, // Error
  ];
}
