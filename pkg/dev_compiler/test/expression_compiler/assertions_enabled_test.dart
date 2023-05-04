// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'expression_compiler_e2e_suite.dart';

void main() async {
  var driver = await TestDriver.init();

  group('dart.web.assertions_enabled', () {
    const source = r'''
      void main() {
        var b = const bool.fromEnvironment('dart.web.assertions_enabled');

        // Breakpoint: bp
        print('hello world');
      }
    ''';

    tearDown(() async {
      await driver.cleanupTest();
    });

    tearDownAll(() async {
      await driver.finish();
    });

    test('is automatically set', () async {
      var setup = SetupCompilerOptions(enableAsserts: true);
      await driver.initSource(setup, source);
      // TODO(43986): Update when assertions are enabled.
      await driver.check(
          breakpointId: 'bp', expression: 'b', expectedResult: 'false');
    });

    test('is automatically unset', () async {
      var setup = SetupCompilerOptions(enableAsserts: false);
      await driver.initSource(setup, source);
      await driver.check(
          breakpointId: 'bp', expression: 'b', expectedResult: 'false');
    });
  });
}
