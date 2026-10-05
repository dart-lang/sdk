// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'package:checks/checks.dart';
import 'package:dartpad/src/worker_client.dart';
import 'package:dartpad_worker/src/worker.dart';
import 'package:fake_async/fake_async.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

import 'asset_server/asset_server_client.dart';
import 'in_process_worker.dart';

extension on Worker {
  WorkerClient sessionWithClient({bool keepAlive = true}) {
    final controller = StreamChannelController<Object?>();
    session(controller.foreign);
    return WorkerClient(controller.local, keepAlive: keepAlive);
  }
}

void main() => test('idle session timeout and keepAlive', () async {
  final server = await AssetServerClient.spawnHybrid();
  final worker = await createInProcessWorkerInstance(server, 'dart');

  fakeAsync((async) {
    final idleClient = worker.sessionWithClient(keepAlive: false);
    final recoveringClient = worker.sessionWithClient(keepAlive: false);
    final activeClient = worker.sessionWithClient();

    // At 5m20s, the 5-minute sweep has started the 40s confirmation timer,
    // so idle sessions are still open. Sending a ping from recoveringClient
    // both verifies it is still open and rescues it during the 40s window.
    async.elapse(const Duration(minutes: 5, seconds: 20));
    check(recoveringClient.ping()).completes();

    // After the 40s confirmation timer fires (at 5m40s), idleClient is
    // closed, while recoveringClient remains open.
    async.elapse(const Duration(seconds: 30));
    check(idleClient.done).completes();
    check(idleClient.ping()).throws();
    check(recoveringClient.ping()).completes();

    // After another 10 minutes, recoveringClient (keepAlive: false) has now
    // timed out, while activeClient's 30s pings keep it open.
    async.elapse(const Duration(minutes: 10));
    check(recoveringClient.done).completes();
    check(activeClient.ping()).completes();
    // Flush so ping() completes before close() is called below.
    async.flushMicrotasks();

    check(activeClient.close()).completes();
    // Flush so close() future completes before fakeAsync exits.
    async.flushMicrotasks();
  });
});
