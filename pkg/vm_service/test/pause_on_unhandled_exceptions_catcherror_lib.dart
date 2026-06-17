// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

Future<void> throwAsync() async {
  await Future.delayed(const Duration(milliseconds: 10));
  throw 'Throw from throwAsync!';
}

Future<void> nestedThrowAsync() async {
  await Future.delayed(const Duration(milliseconds: 10));
  await throwAsync();
}

Future<void> testeeMain() async {
  await throwAsync().then((v) {
    print('Hello from then()!');
  }).catchError((e, st) {
    print('Caught in catchError: $e!');
  });
  // Make sure we can chain through off-stack awaiters as well.
  try {
    await nestedThrowAsync();
  } catch (e) {
    print('Caught in catch: $e!');
  }
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeMain);
}
