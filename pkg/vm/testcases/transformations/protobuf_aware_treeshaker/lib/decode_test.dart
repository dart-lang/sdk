// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'generated/foo.pb.dart';

List<int> buffer = <int>[
  10, 4, 8, 5, 16, //
  4, 26, 9, 10, 3,
  102, 111, 111, 18, 2,
  8, 42, 34, 9, 10,
  3, 122, 111, 112, 18,
  2, 8, 3, 40, 43,
  50, 0, 58, 0,
];

main() {
  FooKeep foo = FooKeep.fromBuffer(buffer);
  test('Kept values are restored correctly', () {
    expect(foo.mapKeep['foo'].aKeep, 42);
    expect(foo.barKeep.aKeep, 5);
    expect(foo.aKeep, 43);
    expect(foo.hasHasKeep(), true);
    foo.clearClearKeep();
  });
}
