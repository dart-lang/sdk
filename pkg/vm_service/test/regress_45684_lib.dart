// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

void tryFinally(Function() code) {
  // There is a synthetic try/catch inside try/finally but it is not authored
  // by the user, so debugger should not consider that this try/catch is
  // going to handle the exception.
  try {
    code();
  } finally {}
}

Never syncThrow() {
  throw 'Hello from syncThrow!'; // LINE_A
}

void testMain() {
  tryFinally(syncThrow);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
