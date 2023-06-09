// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

void testMain() {
  print(123);
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    // Set up a subscription that will complete [completer] when an
    // [IsolateReload] event is received.
    final completer = Completer<void>();
    late final StreamSubscription subscription;
    subscription = service.onIsolateEvent.listen((event) {
      if (event.kind == EventKind.kIsolateReload) {
        expect(event.isolateGroup!.id, isolateRef.isolateGroupId);
        subscription.cancel();
        service.streamCancel(EventStreams.kIsolate);
        completer.complete();
      }
    });
    await service.streamListen(EventStreams.kIsolate);

    // Call the [reloadSources] RPC and ensure that [completer] gets completed.
    await service.reloadSources(
      isolateRef.id!,
      force: true,
      pause: true,
    );
    await completer.future;
  },
];

main([args = const <String>[]]) async => runIsolateTests(
      args,
      tests,
      'reload_sources_rpc_triggers_isolate_reload_event_test.dart',
      testeeConcurrent: testMain,
    );
