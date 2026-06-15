// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'super_constructor_invocation_lib.dart' as testee_lib;

late final String isolateId;
late final String rootLibId;

Future<Response> createInstance(VmService service, String expr) async {
  return await service.evaluate(
    isolateId,
    rootLibId,
    expr,
    disableBreakpoints: true,
  );
}

Future<Obj> evaluateGetter(
  VmService service,
  String instanceId,
  String getter,
) async {
  final dynamic result = await service.evaluate(isolateId, instanceId, getter);
  return await service.getObject(isolateId, result.id);
}

void main([args = const <String>[]]) =>
    IsolateTestHarness('super_constructor_invocation_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          // Initialization
          isolateId = isolateRef.id!;
          final isolate = await service.getIsolate(isolateId);
          rootLibId = isolate.libraries!
              .firstWhere(
                  (l) => l.uri!.contains('super_constructor_invocation_lib'))
              .id!;
        })
        .addCustomTest((VmService service, _) async {
          dynamic instance =
              await createInstance(service, 'C.constr1("abc", t: 42)');
          dynamic result = await evaluateGetter(service, instance.id, 'n');
          expect(result.valueAsString, 'null');
          result = await evaluateGetter(service, instance.id, 't');
          expect(result.valueAsString, '42');
          result = await evaluateGetter(service, instance.id, 'constrName');
          expect(result.valueAsString, 'S');
          result = await service.evaluate(isolateId, instance.id, 'T');
          expect(result.json['name'], 'int');

          instance = await createInstance(service, 'C.constr1("abc", t: "42")');
          result = await evaluateGetter(service, instance.id, 'n');
          expect(result.valueAsString, 'null');
          result = await evaluateGetter(service, instance.id, 't');
          expect(result.valueAsString, '42');
          result = await evaluateGetter(service, instance.id, 'constrName');
          expect(result.valueAsString, 'S');
          result = await service.evaluate(isolateId, instance.id, 'T');
          expect(result.json['name'], 'String');
        })
        .addCustomTest((VmService service, _) async {
          dynamic instance =
              await createInstance(service, 'C.constr2(1, "abc", n: 3.14)');
          dynamic result = await evaluateGetter(service, instance.id, 'n');
          expect(result.valueAsString, '3.14');
          result = await evaluateGetter(service, instance.id, 't');
          expect(result.valueAsString, 'null');
          result = await evaluateGetter(service, instance.id, 'constrName');
          expect(result.valueAsString, 'S');
          result = await service.evaluate(isolateId, instance.id, 'T');
          expect(result.json['name'], 'dynamic');

          instance = await createInstance(service, 'C.constr2(1, "abc", n: 2)');
          result = await evaluateGetter(service, instance.id, 'n');
          expect(result.valueAsString, '2');
          result = await evaluateGetter(service, instance.id, 't');
          expect(result.valueAsString, 'null');
          result = await evaluateGetter(service, instance.id, 'constrName');
          expect(result.valueAsString, 'S');
          result = await service.evaluate(isolateId, instance.id, 'T');
          expect(result.json['name'], 'dynamic');
        })
        .addCustomTest((VmService service, _) async {
          dynamic instance = await createInstance(
            service,
            'C.constr3(1, "abc", n: 42, t: 3.14)',
          );
          dynamic result = await evaluateGetter(service, instance.id, 'n');
          expect(result.valueAsString, '42');
          result = await evaluateGetter(service, instance.id, 't');
          expect(result.valueAsString, '3.14');
          result = await evaluateGetter(service, instance.id, 'constrName');
          expect(result.valueAsString, 'S.named');
          result = await service.evaluate(isolateId, instance.id, 'T');
          expect(result.json['name'], 'double');

          instance = await createInstance(
            service,
            'C.constr3(1, "abc", n: 3.14, t: 42)',
          );
          result = await evaluateGetter(service, instance.id, 'n');
          expect(result.valueAsString, '3.14');
          result = await evaluateGetter(service, instance.id, 't');
          expect(result.valueAsString, '42');
          result = await evaluateGetter(service, instance.id, 'constrName');
          expect(result.valueAsString, 'S.named');
          result = await service.evaluate(isolateId, instance.id, 'T');
          expect(result.json['name'], 'int');
        })
        .addCustomTest((VmService service, _) async {
          final dynamic instance =
              await createInstance(service, 'B(1, 2, 3, 4)');
          dynamic result = await evaluateGetter(service, instance.id, 'f1');
          expect(result.valueAsString, '1');
          result = await evaluateGetter(service, instance.id, 'v1');
          expect(result.valueAsString, '2');
          result = await evaluateGetter(service, instance.id, 'i1');
          expect(result.valueAsString, '3');
          result = await evaluateGetter(service, instance.id, 't1');
          expect(result.valueAsString, '4');
        })
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .addCustomTest((VmService service, _) async {
          dynamic result = await service.evaluateInFrame(isolateId, 0, 'n');
          expect(result.valueAsString, '3.14');
          result = await service.evaluateInFrame(isolateId, 0, 't');
          expect(result.valueAsString, '42');
          result = await service.evaluateInFrame(isolateId, 0, 'constrName');
          expect(result.valueAsString, 'S.named');
        })
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .addCustomTest((VmService service, _) async {
          dynamic result = await service.evaluateInFrame(isolateId, 0, 'f1');
          expect(result.valueAsString, 'a');
          result = await service.evaluateInFrame(isolateId, 0, 'v1');
          expect(result.valueAsString, '3.14');
          result = await service.evaluateInFrame(isolateId, 0, 'i1');
          expect(result.valueAsString, '2.718');
          result = await service.evaluateInFrame(isolateId, 0, 't1');
          expect(result.valueAsString, '42');
        })
        .resumeIsolate()
        .run(testeeMain: testee_lib.main);
