// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'expression_compiler_e2e_suite.dart';
import 'setup_compiler_options.dart';

void main(List<String> args) async {
  var driver = await TestDriver.init();

  group('Assertions |', () {
    const source = r'''
      void main() {
        var b = const bool.fromEnvironment('dart.web.assertions_enabled');

        // Breakpoint: bp
        print('hello world');
      }
      int myAssert() {
        assert(false);
        return 0;
      }
    ''';

    tearDown(() async {
      await driver.cleanupTest();
    });

    tearDownAll(() async {
      await driver.finish();
    });

    test('dart.web.assertions_enabled is set when asserts are enabled',
        () async {
      var setup = SetupCompilerOptions(args: args);
      await driver.initSource(setup, source);

      await driver.check(
          breakpointId: 'bp',
          expression: 'b',
          expectedResult: '${setup.enableAsserts}');
    });

    test('assert errors in the source code when asserts are enabled', () async {
      var setup = SetupCompilerOptions(args: args);
      await driver.initSource(setup, source);

      await driver.check(
        breakpointId: 'bp',
        expression: 'myAssert()',
        expectedResult: setup.enableAsserts
            ? allOf(
                contains('Error: Assertion failed:'),
                contains('test.dart:8:16'),
                contains('false'),
                contains('is not true'),
              )
            : '0',
      );
    });

    test('assert errors in evaluated expression when asserts are enabled',
        () async {
      var setup = SetupCompilerOptions(args: args);
      await driver.initSource(setup, source);

      await driver.check(
        breakpointId: 'bp',
        expression: '() { assert(false); return 0; } ()',
        expectedResult: setup.enableAsserts
            ? allOf(
                contains('Error: Assertion failed:'),
                contains('<unknown source>:-1:-1'),
                contains('BoolLiteral(false)'),
                contains('is not true'),
              )
            : '0',
      );
    });
  });
}
