// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dds/dds.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';

void main() {
  late Process process;
  late DartDevelopmentService dds;

  setUp(() async {
    process = await spawnDartProcess(
      'long_sleep_script.dart',
      pauseOnStart: false,
      subscribeToStdio: false,
    );
  });

  tearDown(() async {
    await dds.shutdown();
    process.kill();
  });

  test('Ensure DDS starts when isolate is blocked', () async {
    // Wait for the Dart program to start running, then wait a bit more to make
    // sure the isolate is actually blocked on the sleep(...) call.
    await process.stdout.transform(utf8.decoder).first;
    await Future.delayed(const Duration(milliseconds: 500));

    print('Starting DDS...');
    // Before the fix for b/323386606, this call would hang as the isolate
    // waiting on the sleep(...) call would never respond to a service request,
    // preventing DDS initialization from completing.
    dds = await DartDevelopmentService.startDartDevelopmentService(
      remoteVmServiceUri,
    );
    print('DDS started');
    expect(dds.isRunning, true);
  });
}
