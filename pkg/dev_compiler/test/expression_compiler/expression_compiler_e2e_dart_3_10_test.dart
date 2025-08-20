// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dev_compiler/src/compiler/module_builder.dart'
    show ModuleFormat;
import 'package:test/test.dart';

import '../shared_test_options.dart';
import 'expression_compiler_e2e_suite.dart';

void main(List<String> args) async {
  var driver = await ExpressionEvaluationTestDriver.init();

  group('Dart 3.10 language features', () {
    tearDownAll(() async {
      await driver.finish();
    });

    group('(AMD module system)', () {
      var setup = SetupCompilerOptions(
        moduleFormat: ModuleFormat.amd,
        args: args,
      );
      runSharedTests(setup, driver);
    });

    group('(DDC module system)', () {
      var setup = SetupCompilerOptions(
        moduleFormat: ModuleFormat.ddc,
        args: args,
      );
      runSharedTests(setup, driver);
    });
  });
}

/// Shared tests for language features introduced in version 3.10.0.
void runSharedTests(
  SetupCompilerOptions setup,
  ExpressionEvaluationTestDriver driver,
) {
  group('local consts', () {
    const recordsSource = '''
    void main() {
      topLevelMethod();

      const mainLocalConst = Duration(seconds: 1);

      inlineMethod() {
        // The const from the outer scope is not available here during
        // evaluation unless there is already a reference within this scope.
        var x = mainLocalConst;
        // Breakpoint: bp1
        print('hello world');
      }

      inlineMethod();
    }

    void topLevelMethod() {
      const methodLocalConst= Duration(seconds: 3);
      // Breakpoint: bp2
      print('hello world');
    }
    ''';

    setUpAll(() async {
      await driver.initSource(setup, recordsSource);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('defined in enclosing scope', () async {
      await driver.checkInFrame(
        breakpointId: 'bp1',
        expression: 'mainLocalConst.toString()',
        expectedResult: '0:00:01.000000',
      );
    });

    test('defined in method', () async {
      await driver.checkInFrame(
        breakpointId: 'bp2',
        expression: 'methodLocalConst.toString()',
        expectedResult: '0:00:03.000000',
      );
    });
  });
}
