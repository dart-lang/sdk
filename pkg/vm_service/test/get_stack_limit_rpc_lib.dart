// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

Future<void> bar(int depth) async {
  if (depth == 21) {
    debugger();
    return;
  }
  await foo(depth + 1);
}

Future<void> foo(int depth) async {
  if (depth == 10) {
    // Yield once to force the rest to run async.
    // ignore: await_only_futures
    await 0;
  }
  await bar(depth + 1);
}

Future<void> testMain() async {
  await foo(0);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
