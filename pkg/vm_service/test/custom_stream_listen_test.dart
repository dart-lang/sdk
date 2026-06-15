// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'custom_stream_listen_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    VMTestHarness('custom_stream_listen_lib.dart', args).addTest(
      // Ensure the VM service throws an exception when encountering a custom
      // stream.
      (VmService service) async {
        try {
          await service.streamListen('Foo');
          fail('Successfully listened to a custom stream, which requires DDS');
        } on RPCError catch (_) {
          // Expected.
        }
      },
    ).run(testeeMain: testee_lib.main, extraArgs: ['--no-dds']);
