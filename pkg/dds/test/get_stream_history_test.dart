// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.10

import 'dart:io';

import 'package:dds/dds.dart';
import 'package:dds/vm_service_extensions.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service_io.dart';
import 'common/test_helper.dart';

void main() {
  Process process;
  DartDevelopmentService dds;

  setUp(() async {
    process = await spawnDartProcess('get_stream_history_script.dart',
        pauseOnStart: false);
  });

  tearDown(() async {
    await dds?.shutdown();
    process?.kill();
    dds = null;
    process = null;
  });

  test('getStreamHistory returns log history', () async {
    dds = await DartDevelopmentService.startDartDevelopmentService(
      remoteVmServiceUri,
    );
    expect(dds.isRunning, true);
    final service = await vmServiceConnectUri(dds.wsUri.toString());
    final result = await service.getStreamHistory('Logging');
    expect(result, isNotNull);
    expect(result, isA<StreamHistory>());
    expect(result.history.length, 10);
  });
}
