// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

Stream<int> method0() async* {
  yield 1;
  yield 2;
}

Future<void> method1() async {
  print('helper');
  await for (var i in method0()) {
    method2();
    print('loop');
  }
  return;
}

void method2() {}
