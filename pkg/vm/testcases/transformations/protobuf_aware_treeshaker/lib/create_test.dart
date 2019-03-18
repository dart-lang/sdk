// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'generated/foo.pb.dart';

main() {
  FooKeep foo = FooKeep()
    ..barKeep = (BarKeep()..aKeep = 5)
    ..mapKeep['foo'] = (BarKeep()..aKeep = 2)
    ..aKeep = 43;
  test('retrieving values', () {
    expect(foo.barKeep.aKeep, 5);
    expect(foo.mapKeep['foo'].aKeep, 2);
    expect(foo.hasHasKeep(), false);
    expect(foo.aKeep, 43);
    foo.clearClearKeep();
  });
}
