// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;

    // Check the default name.
    Isolate isolate = await service.getIsolate(isolateId);
    expect(isolate.name == 'main', true);

    final completer = Completer<void>();
    late final StreamSubscription sub;
    sub = service.onIsolateEvent.listen((event) async {
      if (event.kind == EventKind.kIsolateUpdate) {
        expect(event.isolate!.name, 'Barbara');
        sub.cancel();
        await service.streamCancel(EventStreams.kIsolate);
        completer.complete();
      }
    });
    await service.streamListen(EventStreams.kIsolate);

    await service.setName(isolateId, 'Barbara');
    await completer.future;
    isolate = await service.getIsolate(isolateId);
    expect(isolate.name, 'Barbara');
  }
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'set_name_rpc_test.dart',
    );
