// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';

void verifyMember(ClassHeapStats member) {
  expect(member.json!.containsKey('_new'), false);
  expect(member.json!.containsKey('_old'), false);
  expect(member.json!.containsKey('_promotedInstances'), false);
  expect(member.json!.containsKey('_promotedBytes'), false);
  expect(member.instancesAccumulated, greaterThanOrEqualTo(0));
  expect(member.instancesCurrent, greaterThanOrEqualTo(0));
  expect(member.bytesCurrent, greaterThanOrEqualTo(0));
  expect(member.accumulatedSize, greaterThanOrEqualTo(0));
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    var result = await service.getAllocationProfile(isolateId);
    expect(result.dateLastAccumulatorReset, isNull);
    expect(result.dateLastServiceGC, isNull);
    expect(result.json!.containsKey('_heaps'), false);
    var members = result.members!;
    expect(members, isNotEmpty);

    var member = members.first;
    verifyMember(member);

    // reset.
    result = await service.getAllocationProfile(isolateId, reset: true);
    final firstReset = result.dateLastAccumulatorReset!;
    expect(result.dateLastServiceGC, isNull);
    expect(result.json!.containsKey('_heaps'), false);

    members = result.members!;
    expect(members, isNotEmpty);

    member = members.first;
    verifyMember(member);

    // Create an artificial delay to ensure there's a difference between the
    // reset times.
    await Future.delayed(const Duration(milliseconds: 100));

    result = await service.getAllocationProfile(isolateId, reset: true);
    final secondReset = result.dateLastAccumulatorReset!;
    expect(secondReset, isNot(firstReset));

    // gc.
    result = await service.getAllocationProfile(isolateId, gc: true);
    expect(result.dateLastAccumulatorReset, secondReset);
    final firstGC = result.dateLastServiceGC!;
    expect(result.json!.containsKey('_heaps'), false);

    members = result.members!;
    expect(members, isNotEmpty);

    member = members.first;
    verifyMember(member);

    // Create an artificial delay to ensure there's a difference between the
    // GC times.
    await Future.delayed(const Duration(milliseconds: 100));

    result = await service.getAllocationProfile(isolateId, gc: true);
    final secondGC = result.dateLastServiceGC!;
    expect(secondGC, isNot(firstGC));
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'get_allocation_profile_public_rpc_test.dart',
    );
