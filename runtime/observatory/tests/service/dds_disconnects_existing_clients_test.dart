// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dds/dds.dart';
import 'package:observatory/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

final tests = <VMTest>[
  (VM vm) async {
    late DartDevelopmentService dds;
    final waitForDDS = Completer<void>();
    final serviceMessageCompleter = Completer<void>();

    // The original VM service client is connected.
    expect(vm.isConnected, true);

    // A service event is sent to all existing clients when DDS connects before
    // their connection is closed.
    await vm.listenEventStream('Service', (ServiceEvent event) async {
      // Wait for dds to be set before checking the server's URI.
      await waitForDDS.future;
      final message =
          'A Dart Developer Service instance has connected and this direct '
          'connection to the VM service will now be closed. Please reconnect to '
          'the Dart Development Service at ${dds.uri}.';
      expect(event.kind, ServiceEvent.kDartDevelopmentServiceConnected);
      expect(event.message, message);
      expect(event.uri, dds.uri);
      serviceMessageCompleter.complete();
    });

    // Start DDS, which should result in the original VM service client being
    // disconnected from the VM service.
    final remote = Uri.parse(vm.target.networkAddress);
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
    await vm.onDisconnect;
    await dds.shutdown();
  }
];

main(args) async => runVMTests(
      args,
      tests,
      enableDds: false,
    );
