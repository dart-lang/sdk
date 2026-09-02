// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dwds/dwds.dart';
import 'package:dwds_test_common/fixtures/context.dart';
import 'package:dwds_test_common/fixtures/project.dart';
import 'package:dwds_test_common/fixtures/utilities.dart';
import 'package:dwds_test_common/logging.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:test/test.dart';

void testAll({
  required TestSdkConfigurationProvider provider,
  required TestContextFactory contextFactory,
}) {
  late TestContext context;

  setUp(() {
    setCurrentLogWriter(debug: provider.verbose);
    context = contextFactory(TestProject.test, provider);
  });

  tearDown(() async {
    await context.tearDown();
  });

  test('DWDS starts DDS with a specified port (deprecated)', () async {
    // Find a unused port for the test.
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final expectedPort = server.port;
    await server.close();

    await context.setUp(
      testSettings: TestSettings(
        verboseCompiler: provider.verbose,
        moduleFormat: provider.ddcModuleFormat,
        canaryFeatures: provider.canaryFeatures,
      ),
      debugSettings: const TestDebugSettings.noDevToolsLaunch().copyWith(
        ddsPort: expectedPort,
      ),
    );
    expect(Uri.parse(context.debugConnection.ddsUri!).port, expectedPort);
    expect(context.debugConnection.dtdUri, isNotNull);
  });

  test('DWDS starts DDS with a specified port', () async {
    // Find a unused port for the test.
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final expectedPort = server.port;
    await server.close();

    await context.setUp(
      testSettings: TestSettings(
        verboseCompiler: provider.verbose,
        moduleFormat: provider.ddcModuleFormat,
        canaryFeatures: provider.canaryFeatures,
      ),
      debugSettings: const TestDebugSettings.noDevToolsLaunch().copyWith(
        ddsConfiguration: DartDevelopmentServiceConfiguration(
          port: expectedPort,
        ),
      ),
    );
    expect(Uri.parse(context.debugConnection.ddsUri!).port, expectedPort);
    expect(context.debugConnection.dtdUri, isNotNull);
  });
}
