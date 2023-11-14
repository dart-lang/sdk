// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

class Foo {
  Foo() {
    print('Foo');
  }
}

class Bar {
  Bar() {
    print('Bar');
  }
}

void test() {
  final List l = <Object>[];
  debugger();
  // Toggled on for Foo.
  // Traced allocation.
  l.add(Foo());
  // Untraced allocation.
  l.add(Bar());
  // Toggled on for Bar.
  debugger();
  // Traced allocation.
  l.add(Bar());
  debugger();
}

Future<Class?> getClassFromRootLib(
  VmService service,
  IsolateRef isolateRef,
  String className,
) async {
  final isolate = await service.getIsolate(isolateRef.id!);
  final Library rootLib =
      (await service.getObject(isolate.id!, isolate.rootLib!.id!)) as Library;
  for (ClassRef cls in rootLib.classes!) {
    if (cls.name == className) {
      return (await service.getObject(isolate.id!, cls.id!)) as Class;
    }
  }
  return null;
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(27),

  // Initial.
  (VmService service, IsolateRef isolate) async {
    // Verify initial state of 'Foo'.
    Class fooClass = (await getClassFromRootLib(service, isolate, 'Foo'))!;
    expect(fooClass.name, equals('Foo'));
    expect(fooClass.traceAllocations, false);
    await service.setTraceClassAllocation(isolate.id!, fooClass.id!, true);

    fooClass = await service.getObject(isolate.id!, fooClass.id!) as Class;
    expect(fooClass.traceAllocations, true);
  },

  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(34),

  // Allocation profile.
  (VmService service, IsolateRef isolate) async {
    Class fooClass = (await getClassFromRootLib(service, isolate, 'Foo'))!;
    expect(fooClass.traceAllocations, true);

    final profileResponse = await service.getAllocationTraces(isolate.id!);
    expect(profileResponse, isNotNull);
    expect(profileResponse.samples!.length, 1);
    expect(profileResponse.samples!.first.identityHashCode != 0, true);
    print(profileResponse.samples);

    final instances = await service.getInstances(
      isolate.id!,
      fooClass.id!,
      1,
    );
    expect(instances.totalCount, 1);
    final instance = instances.instances!.first as InstanceRef;
    expect(instance.identityHashCode != 0, isTrue);
    expect(
      instance.identityHashCode,
      profileResponse.samples!.first.identityHashCode,
    );

    await service.setTraceClassAllocation(isolate.id!, fooClass.id!, false);

    fooClass = await service.getObject(isolate.id!, fooClass.id!) as Class;
    expect(fooClass.traceAllocations, false);

    // Trace Bar.
    Class barClass = (await getClassFromRootLib(service, isolate, 'Bar'))!;
    expect(barClass.traceAllocations, false);
    await service.setTraceClassAllocation(isolate.id!, barClass.id!, true);
    barClass = (await getClassFromRootLib(service, isolate, 'Bar'))!;
    expect(barClass.traceAllocations, true);
  },

  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(37),

  (VmService service, IsolateRef isolate) async {
    // Ensure the allocation of `Bar()` was recorded.
    final profileResponse = await service.getAllocationTraces(isolate.id!);
    expect(profileResponse.samples!.length, 2);
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'get_allocation_traces_test.dart',
      testeeConcurrent: test,
    );
