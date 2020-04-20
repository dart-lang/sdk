// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  final aList = <int>[
    1,
    if (oracle()) 2,
    if (oracle()) 3 else -1,
    if (oracle()) if (oracle()) 4,
    for (int i in <int>[5, 6, 7]) i,
    for (int i in <int>[8, 9, 10]) if (oracle()) i,
    for (int i = 11; i <= 14; ++i) i,
  ];
  final aSet = <int>{
    1,
    if (oracle()) 2,
    if (oracle()) 3 else -1,
    if (oracle()) if (oracle()) 4,
    for (int i in <int>[5, 6, 7]) i,
    for (int i in <int>[8, 9, 10]) if (oracle()) i,
    for (int i = 11; i <= 14; ++i) i,
  };
  final aMap = <int, int>{
    1: 1,
    if (oracle()) 2: 2,
    if (oracle()) 3: 3 else -1: -1,
    if (oracle()) if (oracle()) 4: 4,
    for (int i in <int>[5, 6, 7]) i: i,
    for (int i in <int>[8, 9, 10]) if (oracle()) i: i,
    for (int i = 11; i <= 14; ++i) i: i,
  };

  print(aList);
  print(aSet);
  print(aMap);
}

oracle() => true;
