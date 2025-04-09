// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/60256.
//
// Ensures that the VM shuts down immediately after the VM Service fails to
// start during VM initialization. The specific problem that motivated this test
// was that the VM used to get stuck paused at exit when the VM Service failed
// to start during initialization and `--pause-isolates-on-exit` was supplied.

import 'dart:convert' show utf8;
import 'dart:io' show HttpServer, InternetAddress, Process;

import 'package:test/test.dart';

import 'common/utils.dart';

void main() {
  HttpServer? server;
  Process? process;

  tearDown(() async {
    await server?.close();
    server = null;
    process?.kill();
    process = null;
  });

  void runTest({required final bool enableDds}) {
    test(
      'Regress 60256: VM shuts down immediately after the VM Service fails to '
      'start during VM initialization${enableDds ? '' : ' with --disable-dds'}',
      () async {
        server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

        // Force the testee VM Service to fail to start by making it try to bind
        // to the same address [server] is already running on.
        final (spawnedProcess, _) = await spawnDartProcess(
          // We expect the VM to shut down before running the script, so we just
          // pass an arbitrary script here.
          'regress_55559_script.dart',
          enableDds: enableDds,
          vmServicePort: server!.port,
          returnServiceUri: false,
          pauseOnStart: false,
          pauseOnExit: true,
          subscribeToStdio: false,
        );
        process = spawnedProcess;

        final first = utf8.decode(await process!.stderr.first);
        expect(
          first,
          allOf(
            contains('Could not start the VM service'),
            contains(
              'Failed to create server socket',
            ),
          ),
        );
        // Ensure that the VM terminates instead of hanging.
        final exitCode = await process!.exitCode;
        // 255 is the value of kErrorExitCode in runtime/bin/error_exit.h.
        expect(exitCode, 255);
      },
    );
  }

  runTest(enableDds: true);
  runTest(enableDds: false);
}
