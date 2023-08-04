// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

import 'expression_compiler_e2e_suite.dart';
import 'setup_compiler_options.dart';

void main(List<String> args) async {
  var driver = await TestDriver.init();

  group('canary', () {
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
      var setup = SetupCompilerOptions(args: args);
      await driver.initSource(setup, source);

      expect(
          File(driver.dartSdkPath).readAsStringSync(),
          setup.canaryFeatures
              ? contains('canary')
              : isNot(contains('canary')));
    });
  });
}
