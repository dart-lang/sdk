// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

Future<void> throwAsync() async {
  await Future.delayed(const Duration(milliseconds: 100));
  throw 'Throw from throwAsync!';
}

Future<void> testeeMain() async {
  try {
    await [throwAsync()].wait;
  } catch (e) {
    // Ignore.
  }

  try {
    await (throwAsync(), throwAsync()).wait;
  } catch (e) {
    // Ignore.
  }

  await [throwAsync()].wait.catchError((e) {
    // Ignore.
    return [];
  });

  await (throwAsync(), throwAsync()).wait.catchError((e) {
    // Ignore.
    return (null, null);
  });
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeMain);
}
