// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'stream_subscription_lib.dart' as testee_lib;

const kEchoStream = '_Echo';

void main([args = const <String>[]]) =>
    VMTestHarness('stream_subscription_lib.dart', args).addTest(
      // Check double subscription fails.
      (VmService service) async {
        await service.streamListen(kEchoStream);
        try {
          await service.streamListen(kEchoStream);
          fail('Subscribed to stream twice');
        } on RPCError catch (e) {
          expect(e.code, RPCErrorKind.kStreamAlreadySubscribed.code);
          expect(e.message, contains('Stream already subscribed'));
        }
      },
    ).addTest(
      // Check double cancellation fails.
      (VmService service) async {
        await service.streamCancel(kEchoStream);
        try {
          await service.streamCancel(kEchoStream);
          fail('Double cancellation of stream successful');
        } on RPCError catch (e) {
          expect(e.code, RPCErrorKind.kStreamNotSubscribed.code);
          expect(e.message, contains('Stream not subscribed'));
        }
      },
    ).run(testeeMain: testee_lib.main);
