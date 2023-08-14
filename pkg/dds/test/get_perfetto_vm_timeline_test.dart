// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dds/dds.dart';
import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service_io.dart';

import 'common/test_helper.dart';

void main() {
  late final Process process;
  late final DartDevelopmentService dds;

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

  test('Ensure getPerfettoVMTimelineWithCpuSamples returns without error',
      () async {
    dds = await DartDevelopmentService.startDartDevelopmentService(
      remoteVmServiceUri,
    );
    expect(dds.isRunning, true);
    final service = await vmServiceConnectUri(dds.wsUri.toString());

    final timeline = await service.getPerfettoVMTimelineWithCpuSamples(
        timeOriginMicros: 1, timeExtentMicros: 1000);
    expect(timeline.trace!, isNotEmpty);
    expect(timeline.timeOriginMicros, isNotNull);
    expect(timeline.timeExtentMicros, isNotNull);
  });
}
