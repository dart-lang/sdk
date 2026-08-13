// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import '../common/service_test_common.dart';
import 'allocations_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('allocations_lib.dart', args)
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final profile = await service.callMethod(
        '_getAllocationProfile',
        isolateId: isolateRef.id!,
      ) as AllocationProfile;
      print(profile.runtimeType);
      final classHeapStats = profile.members!.singleWhere((stats) {
        return stats.classRef!.name == 'Foo';
      });
      expect(classHeapStats.instancesCurrent, 3);
      expect(classHeapStats.instancesAccumulated, 3);
    }).run(testeeMain: testee_lib.main);
