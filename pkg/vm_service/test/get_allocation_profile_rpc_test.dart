// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'get_allocation_profile_rpc_lib.dart' as testee_lib;

Future<void> sleep(int milliseconds) =>
    Future.delayed(Duration(milliseconds: milliseconds));

void main([args = const <String>[]]) =>
    IsolateTestHarness('get_allocation_profile_rpc_lib.dart', args)
        .addCustomTest((VmService service, IsolateRef isolate) async {
      final isolateId = isolate.id!;

      AllocationProfile result = await service.getAllocationProfile(isolateId);
      expect(result.dateLastAccumulatorReset, isNull);
      expect(result.dateLastServiceGC, isNull);
      expect(result.members!.length, isPositive);

      ClassHeapStats member = result.members![0];
      expect(member.instancesAccumulated, isNotNull);
      expect(member.instancesCurrent, isNotNull);
      expect(member.bytesCurrent, isNotNull);
      expect(member.accumulatedSize, isNotNull);

      // reset.
      result = await service.getAllocationProfile(isolateId, reset: true);
      final firstReset = result.dateLastAccumulatorReset;
      expect(firstReset, isNotNull);
      expect(result.dateLastServiceGC, isNull);
      expect(result.members!.length, isPositive);

      member = result.members![0];
      expect(member.instancesAccumulated, isNotNull);
      expect(member.instancesCurrent, isNotNull);
      expect(member.bytesCurrent, isNotNull);
      expect(member.accumulatedSize, isNotNull);

      await sleep(1000);

      result = await service.getAllocationProfile(isolateId, reset: true);
      final secondReset = result.dateLastAccumulatorReset;
      expect(secondReset, isNot(firstReset));

      // gc.
      result = await service.getAllocationProfile(isolateId, gc: true);
      expect(result.dateLastAccumulatorReset, secondReset);
      final firstGC = result.dateLastServiceGC;
      expect(firstGC, isNotNull);
      expect(result.members!.length, isPositive);

      member = result.members![0];
      expect(member.instancesAccumulated, isNotNull);
      expect(member.instancesCurrent, isNotNull);
      expect(member.bytesCurrent, isNotNull);
      expect(member.accumulatedSize, isNotNull);

      await sleep(1000);

      result = await service.getAllocationProfile(isolateId, gc: true);
      final secondGC = result.dateLastAccumulatorReset;
      expect(secondGC, isNot(firstGC));
    }).run(testeeMain: testee_lib.main);
