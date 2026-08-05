// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

bool testing = false;
void printSync() {
  print('sync');
  if (testing) {
    // LINE_A
    // We'll never reach this code, but setting a breakpoint here will result in
    // the breakpoint being resolved below at line LINE_C.
    print('unreachable'); // LINE_B
  }
}

Iterable<void> printSyncStar() sync* {
  // We'll end up resolving breakpoint 1 to this location instead of at LINE_A
  // if #46419 regresses.
  print('sync*'); // LINE_C
}

void testeeDo() {
  printSync();
  final iterator = printSyncStar();

  print('middle'); // LINE_D

  iterator.toList();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeDo);
}
