// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'set_name_rpc_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('set_name_rpc_lib.dart', args)
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;

      // Check the default name.
      Isolate isolate = await service.getIsolate(isolateId);
      expect(isolate.name == 'main', true);

      final completer = Completer<void>();
      late final StreamSubscription sub;
      sub = service.onIsolateEvent.listen((event) async {
        if (event.kind == EventKind.kIsolateUpdate) {
          expect(event.isolate!.name, 'Barbara');
          await sub.cancel();
          await service.streamCancel(EventStreams.kIsolate);
          completer.complete();
        }
      });
      await service.streamListen(EventStreams.kIsolate);

      await service.setName(isolateId, 'Barbara');
      await completer.future;
      isolate = await service.getIsolate(isolateId);
      expect(isolate.name, 'Barbara');
    }).run(testeeMain: testee_lib.main);
