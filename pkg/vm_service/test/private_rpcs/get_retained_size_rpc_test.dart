// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import '../common/test_helper.dart';

const MB = 1 << 20;

class _TestClass {
  _TestClass(this.x, this.y);
  // Make sure these fields are not removed by the tree shaker.
  @pragma("vm:entry-point")
  var x;
  @pragma("vm:entry-point")
  var y;
}

@pragma("vm:entry-point")
var myVar;

@pragma("vm:entry-point")
invoke1() => myVar = new _TestClass(null, null);

@pragma("vm:entry-point")
invoke2() => myVar = new _TestClass(new _TestClass(null, null), null);

@pragma("vm:entry-point")
invoke3() => myVar = new _TestClass(new WeakReference(new Uint8List(MB)), null);

extension on VmService {
  Future<InstanceRef> getRetainedSize(
    String isolateId,
    String targetId,
  ) async {
    return await callMethod('_getRetainedSize', isolateId: isolateId, args: {
      'targetId': targetId,
    }) as InstanceRef;
  }
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLibId = isolate.rootLib!.id!;

    // One instance of _TestClass retained.
    var evalResult = await service.invoke(
      isolateId,
      rootLibId,
      'invoke1',
      [],
    ) as InstanceRef;
    var result = await service.getRetainedSize(isolateId, evalResult.id!);
    expect(result.kind, InstanceKind.kInt);
    final value1 = int.parse(result.valueAsString!);
    expect(value1, isPositive);

    // Two instances of _TestClass retained.
    evalResult = await service.invoke(
      isolateId,
      rootLibId,
      'invoke2',
      [],
    ) as InstanceRef;
    result = await service.getRetainedSize(isolateId, evalResult.id!);
    expect(result.kind, InstanceKind.kInt);
    final value2 = int.parse(result.valueAsString!);
    expect(value2, isPositive);

    // Size has doubled.
    expect(value2, 2 * value1);

    // Get the retained size for class _TestClass.
    result = await service.getRetainedSize(isolateId, evalResult.classRef!.id!);
    expect(result.kind, InstanceKind.kInt);
    final value3 = int.parse(result.valueAsString!);
    expect(value3, isPositive);
    expect(value3, value2);

    // Target of WeakReference not retained.
    evalResult = await service.invoke(
      isolateId,
      rootLibId,
      'invoke3',
      [],
    ) as InstanceRef;
    result = await service.getRetainedSize(isolateId, evalResult.id!);
    expect(result.kind, InstanceKind.kInt);
    final value4 = int.parse(result.valueAsString!);
    expect(value4, lessThan(MB));
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'get_retained_size_rpc_test.dart',
    );
