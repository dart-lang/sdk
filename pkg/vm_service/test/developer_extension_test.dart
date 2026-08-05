// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'developer_extension_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('developer_extension_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          final isolate = await service.getIsolate(isolateRef.id!);
          // Note: extensions other than those is this test might already be
          // registered by core libraries.
          expect(isolate.extensionRPCs, contains('ext..delay'));
          expect(isolate.extensionRPCs, isNot(contains('ext..error')));
          expect(isolate.extensionRPCs, isNot(contains('ext..exception')));
          expect(isolate.extensionRPCs, isNot(contains('ext..success')));
        })
        .addCustomTest(
          resumeIsolateAndAwaitEvent(EventStreams.kExtension, (event) {
            expect(event.kind, EventKind.kExtension);
            expect(event.extensionKind, 'ALPHA');
            expect(event.extensionData!.data['cat'], equals('dog'));
          }),
        )
        .hasStoppedAtBreakpoint()
        .addCustomTest(
          resumeIsolateAndAwaitEvent(EventStreams.kIsolate, (event) {
            // Check that we received an event when '__error' was registered.
            expect(event.kind, equals(EventKind.kServiceExtensionAdded));
            expect(event.extensionRPC, 'ext..error');
          }),
        )
        // Initial.
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          final isolateId = isolateRef.id!;
          var result = await service.callServiceExtension(
            'ext..delay',
            isolateId: isolateId,
          );

          expect(result.json!['type'], '_delayedType');
          expect(result.json!['method'], equals('ext..delay'));
          expect(result.json!['parameters']['isolateId'], isNotNull);

          try {
            await service.callServiceExtension(
              'ext..error',
              isolateId: isolateId,
            );
          } on RPCError catch (e) {
            expect(e.code, ServiceExtensionResponse.extensionErrorMin);
            expect(e.details, 'My error detail.');
          }

          try {
            await service.callServiceExtension(
              'ext..exception',
              isolateId: isolateId,
            );
          } on RPCError catch (e) {
            expect(e.code, ServiceExtensionResponse.extensionError);
            expect(e.details!.startsWith('I always throw!\n'), isTrue);
          }

          result = await service.callServiceExtension(
            'ext..success',
            isolateId: isolateId,
            args: {
              'apple': 'banana',
            },
          );
          expect(result.json!['type'], '_extensionType');
          expect(result.json!['method'], 'ext..success');
          expect(result.json!['parameters']['isolateId'], isNotNull);
          expect(result.json!['parameters']['apple'], 'banana');
        })
        .run(testeeMain: testee_lib.main);
