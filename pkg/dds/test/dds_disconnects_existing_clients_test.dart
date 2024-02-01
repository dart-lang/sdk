// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dds/dds.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

final tests = <VMTest>[
  (VmService service) async {
    late DartDevelopmentService dds;
    final waitForDDS = Completer<void>();
    final serviceMessageCompleter = Completer<void>();

    // A service event is sent to all existing clients when DDS connects before
    // their connection is closed.
    service.onServiceEvent.listen((event) async {
      // Wait for dds to be set before checking the server's URI.
      await waitForDDS.future;
      final message =
          'A Dart Developer Service instance has connected and this direct '
          'connection to the VM service will now be closed. Please reconnect to '
          'the Dart Development Service at ${dds.uri}.';
      expect(event.kind, 'DartDevelopmentServiceConnected');
      expect(event.json!['message'], message);
      expect(event.json!['uri'], dds.uri.toString());
      serviceMessageCompleter.complete();
    });

    // Start DDS, which should result in the original VM service client being
    // disconnected from the VM service.
    final remote = Uri.parse(service.wsUri!);
    dds = await DartDevelopmentService.startDartDevelopmentService(
      remote.replace(
        scheme: 'http',
        pathSegments: remote.pathSegments.sublist(
          0,
          remote.pathSegments.length - 1,
        ),
      ),
    );
    waitForDDS.complete();
    expect(dds.isRunning, true);
    await serviceMessageCompleter.future;
    await service.onDone;
    await dds.shutdown();
  }
];

void main([args = const <String>[]]) => runVMTests(
      args,
      tests,
      'dds_disconnects_existing_clients_test.dart',
      extraArgs: ['--no-dds'],
    );
