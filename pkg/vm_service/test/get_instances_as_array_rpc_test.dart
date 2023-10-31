// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';

@pragma('vm:entry-point')
class Class {}

@pragma('vm:entry-point')
class Subclass extends Class {}

@pragma('vm:entry-point')
class Implementor implements Class {}

@pragma('vm:entry-point')
var aClass;
@pragma('vm:entry-point')
var aSubclass;
@pragma('vm:entry-point')
var anImplementor;

@pragma('vm:entry-point')
void allocate() {
  aClass = Class();
  aSubclass = Subclass();
  anImplementor = Implementor();
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLibId = isolate.rootLib!.id!;
    final rootLib = await service.getObject(isolateId, rootLibId) as Library;

    Future<void> invoke(String selector) => service.invoke(
          isolateId,
          rootLibId,
          selector,
          const <String>[],
        );

    Future<int> instanceCount(String className,
        {bool includeSubclasses = false,
        bool includeImplementors = false}) async {
      final objectId =
          rootLib.classes!.singleWhere((cls) => cls.name == className).id!;
      final result = await service.getInstancesAsList(
        isolateId,
        objectId,
        includeImplementers: includeImplementors,
        includeSubclasses: includeSubclasses,
      );
      return result.length!;
    }

    expect(await instanceCount('Class'), 0);
    expect(await instanceCount('Class', includeSubclasses: true), 0);
    expect(await instanceCount('Class', includeImplementors: true), 0);

    await invoke('allocate');

    expect(await instanceCount('Class'), 1);
    expect(await instanceCount('Class', includeSubclasses: true), 2);
    expect(await instanceCount('Class', includeImplementors: true), 3);
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'get_instances_as_array_rpc_test.dart',
    );
