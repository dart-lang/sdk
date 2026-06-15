// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'throws_sentinel_lib.dart' as testee_lib;

Future<void> main([args = const <String>[]]) async =>
    await VMTestHarness('throws_sentinel_lib.dart', args)
        .addTest((VmService vm) async {
      try {
        final res = await vm.getIsolate('isolates/12321');
        fail('Expected SentinelException, got $res');
      } on SentinelException catch (e, st) {
        // Ensure stack trace contains actual invocation path.
        final stack = st.toString().split('\n');
        expect(
          stack.where((e) => e.contains('VmService.getIsolate')).length,
          1,
        );
        // Call to vm.getIsolate('isolates/12321').
        expect(
          stack
              .where((e) => e.contains('test/throws_sentinel_test.dart'))
              .length,
          1,
        );
      } catch (e) {
        fail('Expected SentinelException, got $e');
      }
    }).run(testeeMain: testee_lib.main);
