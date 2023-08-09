// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../shared_test_options.dart';
import 'expression_compiler_e2e_suite.dart';

void main(List<String> args) async {
  var driver = await ExpressionEvaluationTestDriver.init();
  var setup = SetupCompilerOptions(args: args);

  group('Asserts', () {
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

    setUpAll(() => driver.initSource(setup, source));
    tearDownAll(() async {
      await driver.cleanupTest();
      await driver.finish();
    });

    if (setup.enableAsserts) {
      group('enabled |', () {
        test('dart.web.assertions_enabled is set', () async {
          await driver.check(
              breakpointId: 'bp', expression: 'b', expectedResult: 'true');
        });

        test('assert errors in the source code', () async {
          await driver.check(
              breakpointId: 'bp',
              expression: 'myAssert()',
              expectedResult: allOf(
                contains('Error: Assertion failed:'),
                contains('test.dart:8:16'),
                contains('false'),
                contains('is not true'),
              ));
        });

        test('assert errors in evaluated expression', () async {
          await driver.check(
              breakpointId: 'bp',
              expression: '() { assert(false); return 0; } ()',
              expectedResult: allOf(
                contains('Error: Assertion failed:'),
                contains('<unknown source>:-1:-1'),
                contains('BoolLiteral(false)'),
                contains('is not true'),
              ));
        });
      });
    }

    if (!setup.enableAsserts) {
      group('disabled |', () {
        test('dart.web.assertions_enabled is not set', () async {
          await driver.check(
              breakpointId: 'bp', expression: 'b', expectedResult: 'false');
        });

        test('no assert errors in the source code', () async {
          await driver.check(
              breakpointId: 'bp',
              expression: 'myAssert()',
              expectedResult: '0');
        });

        test('no assert errors in evaluated expression', () async {
          await driver.check(
              breakpointId: 'bp',
              expression: '() { assert(false); return 0; } ()',
              expectedResult: '0');
        });
      });
    }
  });
}
