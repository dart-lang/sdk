// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';

const kEchoStream = '_Echo';

final tests = <VMTest>[
  // Check double subscription fails.
  (VmService service) async {
    await service.streamListen(kEchoStream);
    try {
      await service.streamListen(kEchoStream);
      fail('Subscribed to stream twice');
    } on RPCError catch (e) {
      expect(e.code, RPCErrorKind.kStreamAlreadySubscribed.code);
      expect(e.message, 'Stream already subscribed');
    }
  },
  // Check double cancellation fails.
  (VmService service) async {
    await service.streamCancel(kEchoStream);
    try {
      await service.streamCancel(kEchoStream);
      fail('Double cancellation of stream successful');
    } on RPCError catch (e) {
      expect(e.code, RPCErrorKind.kStreamNotSubscribed.code);
      expect(e.message, 'Stream not subscribed');
    }
  },
];

void main([args = const <String>[]]) => runVMTests(
      args,
      tests,
      'stream_subscription_test.dart',
    );
