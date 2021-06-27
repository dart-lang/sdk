// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dds/dds.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service_io.dart';
import 'common/test_helper.dart';

void main() {
  late Process process;
  late DartDevelopmentService dds;

  setUp(() async {
    // We don't care what's actually running in the target process for this
    // test, so we're just using an existing one.
    process = await spawnDartProcess(
      'get_stream_history_script.dart',
      pauseOnStart: false,
    );
  });

  tearDown(() async {
    await dds.shutdown();
    process.kill();
  });

  test('Ensure streamListen and streamCancel calls are handled atomically',
      () async {
    dds = await DartDevelopmentService.startDartDevelopmentService(
      remoteVmServiceUri,
    );
    expect(dds.isRunning, true);
    final connection1 = await vmServiceConnectUri(dds.wsUri.toString());
    final connection2 = await vmServiceConnectUri(dds.wsUri.toString());

    for (int i = 0; i < 50; ++i) {
      final listenFutures = <Future>[
        connection1.streamListen('Service'),
        connection2.streamListen('Service'),
      ];
      await Future.wait(listenFutures);

      final cancelFutures = <Future>[
        connection1.streamCancel('Service'),
        connection2.streamCancel('Service'),
      ];
      await Future.wait(cancelFutures);
    }
  });
}
