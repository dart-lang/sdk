// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'debugger_inspect_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('debugger_inspect_lib.dart', args)
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final isolate = await service.getIsolate(isolateId);

      final completer = Completer<void>();
      late StreamSubscription sub;
      sub = service.onDebugEvent.listen((event) async {
        if (event.kind == EventKind.kInspect) {
          expect(event.inspectee!.classRef!.name, 'Point');
          await sub.cancel();
          await service.streamCancel(EventStreams.kDebug);
          completer.complete();
        }
      });

      await service.streamListen(EventStreams.kDebug);

      // Start listening for events first.
      await service.evaluate(
        isolateRef.id!,
        isolate.libraries!
            .firstWhere((l) => l.uri!.contains('debugger_inspect_lib'))
            .id!,
        'testeeDo()',
      );
      await completer.future;
    }).run(testeeMain: testee_lib.main);
