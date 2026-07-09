// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'common/test_helper.dart';

Future<void> doThrowAsync() async {
  await null;
  throw 'Exception'; // LINE_A
}

Future<void> doThrowSync() async {
  throw 'Exception'; // LINE_B
}

Future<void> testeeMain() async {
  await testCatchErrorVariants();
  await doThrowAsync(); // LINE_C
}

Future<void> testCatchErrorVariants() async {
  await testCatchError(doThrowSync);
  await testCatchError(doThrowAsync);
  await testCatchError(() async {
    await doThrowSync();
  });
  await testCatchError(() async {
    await doThrowAsync();
  });
}

Future<void> testCatchError(void Function() f) async {
  await Future<void>(f).catchError((_) {});

  final c = Completer<void>();
  Future(f).catchError(c.completeError); // ignore:unawaited_futures
  try {
    await c.future;
  } catch (_) {}
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeMain);
}
