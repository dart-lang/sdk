// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import '../common/service_test_common.dart';
import 'reachable_size_lib.dart' as testee_lib;

extension on VmService {
  Future<int> getReachableSize(String isolateId, String targetId) async {
    final result = await callMethod(
      '_getReachableSize',
      isolateId: isolateId,
      args: {
        'targetId': targetId,
      },
    ) as InstanceRef;

    return int.parse(result.valueAsString!);
  }

  Future<int> getRetainedSize(String isolateId, String targetId) async {
    final result = await callMethod(
      '_getRetainedSize',
      isolateId: isolateId,
      args: {
        'targetId': targetId,
      },
    ) as InstanceRef;

    return int.parse(result.valueAsString!);
  }
}

Future<void> testReachableSize(
  VmService service,
  IsolateRef isolateRef,
) async {
  final isolateId = isolateRef.id!;
  final isolate = await service.getIsolate(isolateId);
  final rootLibId = isolate.libraries!
      .firstWhere((l) => l.uri!.contains('reachable_size_lib'))
      .id!;

  final p1Ref = await service.evaluate(
    isolateId,
    rootLibId,
    'p1',
  ) as InstanceRef;
  final p1 = await service.getObject(isolateId, p1Ref.id!) as Instance;

  final p2Ref = await service.evaluate(
    isolateId,
    rootLibId,
    'p2',
  ) as InstanceRef;
  final p2 = await service.getObject(isolateId, p2Ref.id!) as Instance;

  // In general, shallow <= retained <= reachable. In this program,
  // 0 < shallow < retained < reachable.

  final p1Shallow = p1.size!;
  final p1Retained = await service.getRetainedSize(isolateId, p1.id!);
  final p1Reachable = await service.getReachableSize(isolateId, p1.id!);

  expect(0, lessThan(p1Shallow));
  expect(p1Shallow, lessThan(p1Retained));
  expect(p1Retained, lessThan(p1Reachable));

  final p2Shallow = p2.size!;
  final p2Retained = await service.getRetainedSize(isolateId, p2.id!);
  final p2Reachable = await service.getReachableSize(isolateId, p2.id!);

  expect(0, lessThan(p2Shallow));
  expect(p2Shallow, lessThan(p2Retained));
  expect(p2Retained, lessThan(p2Reachable));

  expect(p1Shallow, p2Shallow);
  expect(p1Retained, p2Retained);
  expect(p1Reachable, p2Reachable);
}

void main([args = const <String>[]]) =>
    IsolateTestHarness('reachable_size_lib.dart', args)
        .addCustomTest(testReachableSize)
        .run(testeeMain: testee_lib.main);
