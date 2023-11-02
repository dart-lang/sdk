// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';

@pragma("vm:entry-point") // Prevent obfuscation
class _TestConst {
  const _TestConst();
}

_TopLevelClosure() {}

@pragma("vm:entry-point") // Prevent obfuscation
var x;
@pragma("vm:entry-point") // Prevent obfuscation
var fn;

void warmup() {
  x = const _TestConst();
  fn = _TopLevelClosure;
}

@pragma("vm:entry-point") // Prevent obfuscation
getX() => x;

@pragma("vm:entry-point") // Prevent obfuscation
getFn() => fn;

Future<InstanceRef> invoke(String selector) async {
  return await rootService.invoke(
    isolateId,
    isolate.rootLib!.id!,
    selector,
    [],
  ) as InstanceRef;
}

late final VmService rootService;
late final Isolate isolate;
late final String isolateId;

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    isolateId = isolateRef.id!;
    rootService = service;
    isolate = await service.getIsolate(isolateId);
  },
  // Expect a simple path through variable x instead of long path filled
  // with VM objects
  (VmService service, IsolateRef isolateRef) async {
    final target = await invoke('getX');
    final result = await service.getRetainingPath(isolateId, target.id!, 100);
    final elements = result.elements!;
    expect(elements.length, 2);
    expect((elements[0].value as InstanceRef).classRef!.name, '_TestConst');
    expect((elements[1].value as FieldRef).name, 'x');
  },

  // Expect a simple path through variable fn instead of long path filled
  // with VM objects
  (VmService service, IsolateRef isolateRef) async {
    final target = await invoke('getFn');
    final result = await service.getRetainingPath(isolateId, target.id!, 100);
    final elements = result.elements!;
    expect(elements.length, 2);
    expect((elements[0].value as InstanceRef).classRef!.name, '_Closure');
    expect((elements[1].value as FieldRef).name, 'fn');
  }
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'get_user_level_retaining_path_rpc_test.dart',
      testeeBefore: warmup,
    );
