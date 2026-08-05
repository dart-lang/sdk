// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'rpc_error_lib.dart' as testee_lib;

Future<void> main([args = const <String>[]]) async => await VMTestHarness(
      'rpc_error_lib.dart',
      args,
    ).addTest((VmService vm) async {
      // Invoke a nonexistent RPC.
      try {
        final res = await vm.callMethod('foo');
        fail('Expected RPCError, got $res');
      } on RPCError catch (e, st) {
        // Ensure stack trace contains actual invocation path.
        final stack = st.toString().split('\n');
        expect(
          stack.where((e) => e.contains('VmService.callMethod')).length,
          1,
        );
        // Call to vm.callMethod('foo').
        expect(
          stack.where((e) => e.contains('test/rpc_error_test.dart')).length,
          1,
        );
      } catch (e) {
        fail('Expected RPCError, got $e');
      }
    }).run(testeeMain: testee_lib.main);
