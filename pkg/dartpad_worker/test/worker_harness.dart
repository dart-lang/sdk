// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dartpad/src/worker_client.dart';
import 'package:dartpad_worker/src/worker.dart';
import 'package:test/test.dart';

import 'asset_server/asset_server_client.dart';

export 'package:dartpad_worker/src/shared.dart';
export 'package:test/test.dart' show fail, group, printOnFailure;

export 'checks_ext.dart';

/// Function used by [testDartWorker] and [testDartWorkspace] to create a
/// worker.
///
/// This defaults to a function creating the worker in the same process, this
/// has several benefits:
///  * It works when testing on VM and in browser.
///  * Faster local iteration, as we don't need to recompile the WASM worker,
///    since the entire worker is compiled into the test program.
///  * Stack traces from the worker are better (especially on the VM).
///  * Printed messages from the worker appear in console for easy debugging.
///  * You can attach a debugger to the whole process.
///
/// The downside of not testing the worker in a _Web Worker_ is that:
///  * Our testing won't cover:
///    - IPC communication,
///    - Worker setup, and,
///    - Cross origin request issues.
///  * The entire worker is compiled along side the test code, so the time to
///    compile a test case is non-trivial.
///
/// To mitigate the compilation time issue, all worker tests are imported into
/// `test_worker.dart` which then calls the `main()` functions. To ensure that
/// we also test with the DartPad worker running as a _Web Worker_ the
/// `integration/test_worker_integration.dart` will override [createWorker] and
/// run all the worker tests with the worker running in a _Web Worker_.
Future<WorkerClient> Function(AssetServerClient server, String sdkPath)
createWorker = (_, _) =>
    throw StateError('createWorker function must be defined!');

AssetServerClient? _serverClient;

/// Define a test that uses a [WorkerClient].
void testDartWorker(
  String description,
  Future<void> Function(WorkerClient worker) body,
) {
  test(description, () async {
    // Create a test server, if one is not already running.
    var sc = _serverClient;
    if (sc == null || sc.isClosed) {
      sc = _serverClient = await AssetServerClient.spawnHybrid(stayAlive: true);
    }

    final worker = await createWorker(sc, 'dart');

    try {
      await body(worker);
    } finally {
      await worker.dispose();
    }
  });
}

/// Define a test that uses [Workspace] pre-populated with a `pubspec.yaml` that
/// has no dependencies.
void testDartWorkspace(
  String description,
  Future<void> Function(Workspace ws) body,
) {
  testDartWorker(description, (worker) async {
    final ws = await worker.createWorkspace();
    await ws.writeFileFromText('pubspec.yaml', '''
      name: myapp
      environment:
        sdk: '>=3.12.0 <4.0.0'
    ''');
    final (:log) = await ws.pub(command: 'get', args: ['--offline']);
    printOnFailure(log);

    try {
      await body(ws);
    } finally {
      await ws.dispose();
    }
  });
}

/// Define a test that runs with a fresh [WorkerClient] connected to an
/// in-memory [Worker] using the Flutter SDK.
void testFlutterWorker(
  String description,
  Future<void> Function(WorkerClient worker) body,
) {
  test(description, () async {
    // Create a test server, if one is not already running.
    var sc = _serverClient;
    if (sc == null || sc.isClosed) {
      sc = _serverClient = await AssetServerClient.spawnHybrid(stayAlive: true);
    }

    if (!sc.hasFlutter) {
      markTestSkipped(
        'Run pkg/dartpad_worker/tool/setup_local_flutter.dart to '
        'enable flutter tests',
      );
      return;
    }

    final worker = await createWorker(sc, 'flutter');

    try {
      await body(worker);
    } finally {
      await worker.dispose();
    }
  });
}

/// Define a test that runs with a fresh [Workspace] connected to an
/// in-memory [Worker] using the Flutter SDK.
void testFlutterWorkspace(
  String description,
  Future<void> Function(Workspace ws) body,
) {
  testFlutterWorker(description, (worker) async {
    final ws = await worker.createWorkspace();
    await ws.writeFileFromText('pubspec.yaml', r'''
      name: myapp
      environment:
        sdk: '>=3.12.0 <4.0.0'
      dependencies:
        flutter:
          sdk: flutter
    ''');
    final (:log) = await ws.pub(command: 'get');
    printOnFailure(log);

    try {
      await body(ws);
    } finally {
      await ws.dispose();
    }
  });
}
