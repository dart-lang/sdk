// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dwds/dwds.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import 'fixtures/context.dart';
import 'fixtures/project.dart';
import 'fixtures/utilities.dart';

void testAll({required TestSdkConfigurationProvider provider}) {
  final context = TestContext(TestProject.test, provider);

  setUpAll(() async {
    // Disable DDS as we're testing DWDS behavior.
    await context.setUp(
      testSettings: TestSettings(
        verboseCompiler: provider.verbose,
        moduleFormat: provider.ddcModuleFormat,
        canaryFeatures: provider.canaryFeatures,
      ),
      debugSettings: const TestDebugSettings.noDevToolsLaunch().copyWith(
        spawnDds: false,
        ddsConfiguration: const DartDevelopmentServiceConfiguration(
          enable: false,
        ),
      ),
    );
  });

  tearDownAll(() async {
    await context.tearDown();
  });

  test('Refuses connections without the auth token', () async {
    expect(
      vmServiceConnectUri('ws://localhost:${context.debugConnection.port}/ws'),
      throwsA(isA<WebSocketException>()),
    );
  });

  test('Accepts connections with the auth token', () async {
    expect(
      vmServiceConnectUri(
        '${context.debugConnection.uri}/ws',
      ).then((client) => client.dispose()),
      completes,
    );
  });

  test('Refuses additional connections when in single client mode', () async {
    final fakeDds = await vmServiceConnectUri(
      '${context.debugConnection.uri}/ws',
    );
    final result = await fakeDds.callMethod(
      '_yieldControlToDDS',
      args: {'uri': 'http://localhost:123'},
    );
    expect(result, isA<Success>());

    // While DDS is connected, expect additional connections to fail.
    await expectLater(
      vmServiceConnectUri('${context.debugConnection.uri}/ws'),
      throwsA(isA<WebSocketException>()),
    );

    // However, once DDS is disconnected, additional clients can connect again.
    await fakeDds.dispose();
    expect(
      vmServiceConnectUri(
        '${context.debugConnection.uri}/ws',
      ).then((client) => client.dispose()),
      completes,
    );
  });

  test('Refuses to yield to dwds if existing clients found', () async {
    final fakeDds = await vmServiceConnectUri(
      '${context.debugConnection.uri}/ws',
    );

    // Connect to vm service.
    final client = await vmServiceConnectUri(
      '${context.debugConnection.uri}/ws',
    );

    final result = await fakeDds.callMethod(
      '_yieldControlToDDS',
      args: {'uri': 'http://localhost:123'},
    );
    expect(result, isA<Success>());

    // The other VM service client should be closed automatically.
    await client.onDone;
    await fakeDds.dispose();
  });
}
