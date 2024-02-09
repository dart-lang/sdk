// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import '../common/test_helper.dart';

class Pair {
  // Make sure these fields are not removed by the tree shaker.
  @pragma('vm:entry-point') // Prevent obfuscation
  dynamic x;
  @pragma('vm:entry-point') // Prevent obfuscation
  dynamic y;
}

@pragma('vm:entry-point') // Prevent obfuscation
dynamic p1;
@pragma('vm:entry-point') // Prevent obfuscation
dynamic p2;

void buildGraph() {
  p1 = Pair();
  p2 = Pair();

  // Adds to both reachable and retained size.
  p1.x = <dynamic>[];
  p2.x = <dynamic>[];

  // Adds to reachable size only.
  p1.y = p2.y = <dynamic>[];
}

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

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLibId = isolate.rootLib!.id!;

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
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'reachable_size_test.dart',
      testeeBefore: buildGraph,
    );
