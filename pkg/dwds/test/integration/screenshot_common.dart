// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dwds_test_common/logging.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:test/test.dart';

import 'fixtures/context.dart';
import 'fixtures/project.dart';
import 'fixtures/utilities.dart';

void testAll({required TestSdkConfigurationProvider provider}) {
  final context = TestContext(TestProject.test, provider);

  setUpAll(() async {
    setCurrentLogWriter(debug: provider.verbose);
    await context.setUp(
      testSettings: TestSettings(
        verboseCompiler: provider.verbose,
        moduleFormat: provider.ddcModuleFormat,
        canaryFeatures: provider.canaryFeatures,
      ),
    );
  });

  tearDownAll(() async {
    await context.tearDown();
  });

  test('can take screenshots', () async {
    final response = await context.debugConnection.vmService
        .callServiceExtension('ext.dwds.screenshot');
    expect(response.json!['data'], isNotNull);
  });
}
