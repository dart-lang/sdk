// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'reload_sources_rpc_triggers_isolate_reload_event_lib.dart'
    as testee_lib;

void main([List<String> args = const <String>[]]) {
  IsolateTestHarness(
    'reload_sources_rpc_triggers_isolate_reload_event_lib.dart',
    args,
  ).addCustomTest((VmService service, IsolateRef isolateRef) async {
    // Set up a subscription that will complete [completer] when an
    // [IsolateReload] event is received.
    final completer = Completer<void>();
    late final StreamSubscription subscription;
    subscription = service.onIsolateEvent.listen((event) async {
      if (event.kind == EventKind.kIsolateReload) {
        expect(event.isolateGroup!.id, isolateRef.isolateGroupId);
        await subscription.cancel();
        await service.streamCancel(EventStreams.kIsolate);
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
  }).run(testeeMain: testee_lib.main);
}
