// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'get_vm_timeline_micros_rpc_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    VMTestHarness('get_vm_timeline_micros_rpc_lib.dart', args)
        .addTest((VmService service) async {
      final result = await service.getVMTimelineMicros();
      expect(result.timestamp, isPositive);
    }).run(testeeMain: testee_lib.main);
