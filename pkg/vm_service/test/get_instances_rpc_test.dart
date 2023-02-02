// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import "package:test/test.dart";
import 'package:vm_service/vm_service.dart';

import "common/service_test_common.dart";
import "common/test_helper.dart";

class Class {}

class Subclass extends Class {}

class Implementor implements Class {}

late final Class aClass;
late final Subclass aSubclass;
late final Implementor anImplementor;

testMain() {
  debugger();
  final _ = 1;

  aClass = new Class();
  aSubclass = new Subclass();
  anImplementor = new Implementor();
}

IsolateTest createTestThatExpectsInstanceCounts(
    int numInstances,
    int numInstancesWhenIncludingSubclasses,
    int numInstancesWhenIncludingImplementers) {
  return (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLib =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;

    Future<int> instanceCount(String className,
        {bool includeSubclasses = false,
        bool includeImplementers = false}) async {
      final result = await service.getInstances(
        isolateId,
        rootLib.classes!.singleWhere((cls) => cls.name == className).id!,
        10,
        includeSubclasses: includeSubclasses,
        includeImplementers: includeImplementers,
      );
      expect(result.totalCount, result.instances!.length);
      return result.totalCount!;
    }

    expect(await instanceCount("Class"), numInstances);
    expect(await instanceCount("Class", includeSubclasses: true),
        numInstancesWhenIncludingSubclasses);
    expect(await instanceCount("Class", includeImplementers: true),
        numInstancesWhenIncludingImplementers);
  };
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(25),
  createTestThatExpectsInstanceCounts(0, 0, 0),
  resumeIsolate,
  createTestThatExpectsInstanceCounts(1, 2, 3),
];

main([args = const <String>[]]) async =>
    runIsolateTests(args, tests, 'get_instances_rpc_test.dart',
        testeeConcurrent: testMain);
