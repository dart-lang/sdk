// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

class _TestVmService extends VmService {
  _TestVmService(
    super.inStream,
    super.writeMessage, {
    super.log,
    super.disposeHandler,
    super.streamClosed,
    super.wsUri,
  });

  static _TestVmService defaultFactory({
    required Stream<dynamic> /*String|List<int>*/ inStream,
    required void Function(String message) writeMessage,
    Log? log,
    DisposeHandler? disposeHandler,
    Future? streamClosed,
    String? wsUri,
  }) {
    return _TestVmService(
      inStream,
      writeMessage,
      log: log,
      disposeHandler: disposeHandler,
      streamClosed: streamClosed,
      wsUri: wsUri,
    );
  }

  final callHistory = <String>[];

  int callCount = 0;

  @override
  Future<T> wrapFuture<T>(String name, Future<T> future) async {
    callHistory.add(name);
    callCount++;
    return future;
  }
}

var tests = <VMTest>[
  // Call a methods and verify wrapper was called.
  (VmService service) async {
    final testService = service as _TestVmService;
    // Verify starting state.
    expect(testService.callHistory, ['getVM']);
    expect(testService.callCount, 1);

    // Execute a few calls to ensure the wrapper continues to get called.
    await testService.getVersion();
    await testService.getVMTimelineMicros();
    await testService.getFlagList();

    expect(
      testService.callHistory,
      ['getVM', 'getVersion', 'getVMTimelineMicros', 'getFlagList'],
    );
    expect(testService.callCount, 4);
  },
];

main([args = const <String>[]]) async => runVMTests(
      args,
      tests,
      'wrap_future_test.dart',
      serviceFactory: _TestVmService.defaultFactory,
    );
