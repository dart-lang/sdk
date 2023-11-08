// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

import '../shared_test_options.dart';
import 'expression_compiler_e2e_suite.dart';

void main(List<String> args) async {
  var driver = await ExpressionEvaluationTestDriver.init();
  var setup = SetupCompilerOptions(args: args);
  var mode = setup.canaryFeatures ? 'canary' : 'stable';

  group('$mode mode', () {
    const source = r'''
      void main() {
        print('hello world');
      }
    ''';

    tearDown(() async {
      await driver.cleanupTest();
    });

    tearDownAll(() async {
      await driver.finish();
    });

    test('is automatically set to the configuration value', () async {
      await driver.initSource(setup, source);

      expect(
          File(driver.dartSdkPath).readAsStringSync(),
          setup.canaryFeatures
              ? contains('canary')
              : isNot(contains('canary')));
    });
  });
}
