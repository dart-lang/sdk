// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'common/test_helper.dart';

class VMServiceClient {
  VMServiceClient(this.x);
  Future<void> close() => Future.microtask(() => print('close'));
  final String x;
}

Future<void> collect() async {
  final uri = 'abc';
  late VMServiceClient vmService;
  await Future.microtask(() async {
    try {
      vmService = VMServiceClient(uri);
      await Future.microtask(() => throw TimeoutException('here'));
    } on Object {
      await vmService.close();
      rethrow; // LINE_A
    }
  });
}

Future<void> testCode() async {
  try {
    await collect(); // LINE_B
  } on TimeoutException {
    print('ok'); // LINE_C
  }
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testCode);
}
