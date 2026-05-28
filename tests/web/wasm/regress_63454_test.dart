// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  print('main start');
  final value = Object();
  final map = <Unused, int>{};
  for (final entry in map.entries) {
    print('before');
    entry.key.foo = value;
    print('after');
  }
  print('main end');
}

class Unused {
  Object? foo;
}
