// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

Future<Never> throwException() async {
  throw 'exception'; // LINE_A
}

Future<void> testeeMain() async {
  try {
    await throwException(); // LINE_B
  } finally {
    try {
      await throwException(); // LINE_C
    } finally {}
  }
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeMain);
}
