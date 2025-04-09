// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Ensures that the VM does not shut down when an attempt to start the VM
// Service via SIGQUIT fails. The VM Service SIGQUIT handler shares nearly all
// of its code with dart:developer's controlWebServer, so this effecitvely tests
// that function too.

import 'dart:async' show Completer;
import 'dart:convert' show utf8;
import 'dart:io'
    show HttpServer, InternetAddress, Platform, Process, ProcessSignal;

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
      'VM does not shut down when the VM Service fails to start after the VM '
      'is initialized${enableDds ? '' : ' with --disable-dds'}',
      () async {
        const vmServicePort = 8282;

        final (spawnedProcess, _) = await spawnDartProcess(
          // We reuse 'sigquit_starts_service_script.dart' here because it just
          // waits in a loop.
          'sigquit_starts_service_script.dart',
          enableDds: enableDds,
          vmServicePort: vmServicePort,
          pauseOnStart: false,
          pauseOnExit: true,
          subscribeToStdio: false,
        );
        process = spawnedProcess;

        // Listen for the messages that should be printed when we toggle the VM
        // Service.
        final vmServiceShutDownCompleter = Completer<void>();
        process!.stdout.transform(utf8.decoder).listen((message) {
          if (message.contains('Dart VM service no longer listening on ')) {
            vmServiceShutDownCompleter.complete();
          }
        });
        final vmServiceFailedToStartCompleter = Completer<void>();
        process!.stderr.transform(utf8.decoder).listen((message) {
          if (message.contains('Could not start the VM service')) {
            vmServiceFailedToStartCompleter.complete();
          }
        });

        // Shut down the VM Service running in the testee.
        process!.kill(ProcessSignal.sigquit);
        await vmServiceShutDownCompleter.future;
        // Wait a bit more to make sure that [vmServicePort] is free.
        await Future.delayed(const Duration(seconds: 3));

        // Bind an HTTP server to [vmServicePort].
        server = await HttpServer.bind(
          InternetAddress.loopbackIPv4,
          vmServicePort,
        );

        // Try restarting the VM Service running in the testee. This should fail
        // because [server] is bound to [vmServicePort].
        process!.kill(ProcessSignal.sigquit);
        await vmServiceFailedToStartCompleter.future;

        process!.kill();
        // Check that the process only exited after receiving SIGTERM, and not
        // when the VM Service failed to start.
        expect(await process!.exitCode, -ProcessSignal.sigterm.signalNumber);
      },
      skip: Platform.isWindows,
    );
  }

  runTest(enableDds: true);
  runTest(enableDds: false);
}
