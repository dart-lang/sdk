// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

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

buildGraph() {
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

    final p1_shallow = p1.size!;
    final p1_retained = await service.getRetainedSize(isolateId, p1.id!);
    final p1_reachable = await service.getReachableSize(isolateId, p1.id!);

    expect(0, lessThan(p1_shallow));
    expect(p1_shallow, lessThan(p1_retained));
    expect(p1_retained, lessThan(p1_reachable));

    final p2_shallow = p2.size!;
    final p2_retained = await service.getRetainedSize(isolateId, p2.id!);
    final p2_reachable = await service.getReachableSize(isolateId, p2.id!);

    expect(0, lessThan(p2_shallow));
    expect(p2_shallow, lessThan(p2_retained));
    expect(p2_retained, lessThan(p2_reachable));

    expect(p1_shallow, p2_shallow);
    expect(p1_retained, p2_retained);
    expect(p1_reachable, p2_reachable);
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'reachable_size_test.dart',
      testeeBefore: buildGraph,
    );
