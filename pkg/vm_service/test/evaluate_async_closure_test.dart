// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'evaluate_async_closure_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('evaluate_async_closure_lib.dart', args)
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      const test = '''(){
          var k = () { return Future.value(3); };
          var w = () async { return await k(); };
          return w();
        }()''';
      final isolateId = isolateRef.id!;
      final isolate = await service.getIsolate(isolateId);
      final rootLibId = isolate.libraries!
          .firstWhere((l) => l.uri!.contains('evaluate_async_closure_lib'))
          .id!;
      final result = await service.evaluate(
        isolateId,
        rootLibId,
        test,
      ) as InstanceRef;
      expect(result.kind, InstanceKind.kPlainInstance);
      expect(result.classRef!.name, '_Future');
    }).run(testeeMain: testee_lib.main);
