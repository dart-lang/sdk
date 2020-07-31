// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'generated/foo.pb.dart';

main() {
  FooKeep foo = FooKeep()
    ..barKeep = (BarKeep()
      ..aKeep = 5
      ..bDrop = 4)
    ..mapKeep['foo'] = (BarKeep()..aKeep = 42)
    ..mapDrop['zop'] = (ZopDrop()..aDrop = 3)
    ..aKeep = 43
    ..hasKeep = HasKeep()
    ..clearKeep = ClearKeep();
  final buffer = foo.writeToBuffer();
  print('List<int> buffer = <int>[');
  for (int i = 0; i < buffer.length; i += 5) {
    final numbers = buffer.sublist(i, min(buffer.length, i + 5)).join(', ');
    print('  $numbers,${i == 0 ? ' //' : ''}');
  }
  print('];');
}
