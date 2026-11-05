// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const List<int> intList = <int>[3, 4, 5];
const Map<int, String> intMap = <int, String>{0: '0', 1: '1', 2: '2'};
const List<(int, int)> intIntList = <(int, int)>[(12, 13), (14, 15)];

test() {
  const <num, String>{
    for (int i = 0; i < intList.length; i++) // Error
      intList[i]: '${intList[i]}',
    for (var (i, j) = (0, 1); i < intList.length; i++) // Error
      intList[i]: '$j',
    for (var e in intMap.entries) e.key: e.value, // Error
    for (var (a, b) in intIntList) a: '$b', // Error
  };
}
