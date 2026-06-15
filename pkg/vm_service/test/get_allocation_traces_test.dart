// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'get_allocation_traces_lib.dart' as testee_lib;

Future<Class?> getClassFromRootLib(
  VmService service,
  IsolateRef isolateRef,
  String className,
) async {
  final isolate = await service.getIsolate(isolateRef.id!);
  final Library rootLib = (await service.getObject(
      isolate.id!,
      isolate.libraries!
          .firstWhere((l) => l.uri!.contains('get_allocation_traces_lib'))
          .id!)) as Library;
  for (ClassRef cls in rootLib.classes!) {
    if (cls.name == className) {
      return (await service.getObject(isolate.id!, cls.id!)) as Class;
    }
  }
  return null;
}

late Class fooClass;
late Class barClass;

void main([args = const <String>[]]) => IsolateTestHarness(
      'get_allocation_traces_lib.dart',
      args,
    )
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        // Initial.
        .addCustomTest((VmService service, IsolateRef isolate) async {
          // Verify initial state of 'Foo'.
          fooClass = (await getClassFromRootLib(service, isolate, 'Foo'))!;
          expect(fooClass.name, equals('Foo'));
          expect(fooClass.traceAllocations, false);
          await service.setTraceClassAllocation(
              isolate.id!, fooClass.id!, true);

          fooClass =
              await service.getObject(isolate.id!, fooClass.id!) as Class;
          expect(fooClass.traceAllocations, true);
        })
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        // Allocation profile.
        .addCustomTest((VmService service, IsolateRef isolate) async {
          fooClass = (await getClassFromRootLib(service, isolate, 'Foo'))!;
          expect(fooClass.traceAllocations, true);

          final profileResponse =
              await service.getAllocationTraces(isolate.id!);
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

          await service.setTraceClassAllocation(
              isolate.id!, fooClass.id!, false);

          fooClass =
              await service.getObject(isolate.id!, fooClass.id!) as Class;
          expect(fooClass.traceAllocations, false);

          // Trace Bar.
          barClass = (await getClassFromRootLib(service, isolate, 'Bar'))!;
          expect(barClass.traceAllocations, false);
          await service.setTraceClassAllocation(
              isolate.id!, barClass.id!, true);
          barClass = (await getClassFromRootLib(service, isolate, 'Bar'))!;
          expect(barClass.traceAllocations, true);
          print('Allocation tracing enabled for Bar');
        })
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_C')
        .addCustomTest((VmService service, IsolateRef isolate) async {
          // Ensure the allocation of `Bar()` was recorded.
          final profileResponse =
              await service.getAllocationTraces(isolate.id!);
          final samples = profileResponse.samples!;
          if (samples.length != 2) {
            print('Foo ID: ${fooClass.id}');
            print('Bar ID: ${barClass.id}');
            final functions = profileResponse.functions!;
            for (final sample in samples) {
              print('Sample for CID: ${sample.classId}');
              for (int i = 0; i < sample.stack!.length; ++i) {
                final frame = sample.stack![i];
                final location =
                    (functions[frame].function as FuncRef).location!;
                print('$i: ${location.script!.uri}:${location.line}');
              }
            }
          }
          expect(profileResponse.samples!.length, 2);
        })
        .run(testeeMain: testee_lib.main);
