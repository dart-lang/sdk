// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// These tests make it clear what the evaluations result to at the time this
// test was authored, but they might not actually be desired.
// If changes cause these tests to fail but offer better functionality
// while debugging then feel free to update the expectations.

import 'package:dev_compiler/src/compiler/module_builder.dart'
    show ModuleFormat;
import 'package:test/test.dart';

import '../shared_test_options.dart';
import 'expression_compiler_e2e_suite.dart';

const conflictingTopLevelFieldsSource = '''
final x = 99;
final _x = 42;
''';

const source = '''
class C {
  String _x;

  // Breakpoint: bp1
  C({required String x}) : _x = x {
    // Breakpoint: bp2
    print('from C constructor body');
  }
}

class C2 {
  String _x;
  // Breakpoint: bp3
  C2({required this._x}) {
    // Breakpoint: bp4
    print('from C2 constructor body');
  }
}

void main() {
  C(x: 'hello');
  C2(x: 'goodbye');
}
''';

void main(List<String> args) async {
  var driver = await ExpressionEvaluationTestDriver.init();

  group('Dart 3.12 language features', () {
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

/// Shared tests for language features introduced in version 3.12.0.
void runSharedTests(
  SetupCompilerOptions setup,
  ExpressionEvaluationTestDriver driver,
) {
  group('No top-level name conflicts', () {
    setUpAll(() async {
      await driver.initSource(setup, source);
    });
    tearDownAll(() async {
      await driver.cleanupTest();
    });
    group('paused at constructor definition', () {
      test('conventional public named parameter', () async {
        await driver.checkInFrame(
          breakpointId: 'bp1',
          expression: 'x',
          // See: https://github.com/dart-lang/sdk/issues/63842.
          expectedError:
              "Failed to read the 'x' property from 'Object': "
              "Cannot access 'x' from debugger",
        );
        await driver.checkInFrame(
          breakpointId: 'bp1',
          expression: '_x',
          // See: https://github.com/dart-lang/sdk/issues/63842.
          expectedError:
              "Failed to read the 'x' property from 'Object': "
              "Cannot access 'x' from debugger",
        );
      });
      test('private named parameter', () async {
        await driver.checkInFrame(
          breakpointId: 'bp3',
          expression: 'x',
          // See: https://github.com/dart-lang/sdk/issues/63842.
          expectedError:
              "Failed to read the 'x' property from 'Object': "
              "Cannot access 'x' from debugger",
        );
        await driver.checkInFrame(
          breakpointId: 'bp3',
          expression: '_x',
          // See: https://github.com/dart-lang/sdk/issues/63842.
          expectedError:
              "Failed to read the 'x' property from 'Object': "
              "Cannot access 'x' from debugger",
        );
      });
    });
    group('paused in constructor body', () {
      test('conventional public named parameter', () async {
        await driver.checkInFrame(
          breakpointId: 'bp2',
          expression: 'x',
          expectedResult: 'hello',
        );
        await driver.checkInFrame(
          breakpointId: 'bp2',
          expression: '_x',
          expectedResult: 'hello',
        );
      });
      test('private named parameter', () async {
        await driver.checkInFrame(
          breakpointId: 'bp4',
          expression: 'x',
          // See: https://github.com/dart-lang/sdk/issues/63842.
          expectedError:
              "DartError: NoSuchMethodError: 'x'\n"
              'method not found\n'
              "Receiver: Instance of 'C2'\n"
              'Arguments: []\n',
        );
        await driver.checkInFrame(
          breakpointId: 'bp4',
          expression: '_x',
          expectedResult: 'goodbye',
        );
      });
    });
  });
  group('With top-level name conflicts', () {
    setUpAll(() async {
      await driver.initSource(
        setup,
        '$conflictingTopLevelFieldsSource\n$source',
      );
    });
    tearDownAll(() async {
      await driver.cleanupTest();
    });
    group('paused at constructor definition', () {
      test('conventional public named parameter', () async {
        await driver.checkInFrame(
          breakpointId: 'bp1',
          expression: 'x',
          // See: https://github.com/dart-lang/sdk/issues/63842.
          expectedError:
              "Failed to read the 'x' property from 'Object': "
              "Cannot access 'x' from debugger",
        );
        await driver.checkInFrame(
          breakpointId: 'bp1',
          expression: '_x',
          // See: https://github.com/dart-lang/sdk/issues/63842.
          expectedError:
              "Failed to read the 'x' property from 'Object': "
              "Cannot access 'x' from debugger",
        );
      });
      test('private named parameter', () async {
        await driver.checkInFrame(
          breakpointId: 'bp3',
          expression: 'x',
          // See: https://github.com/dart-lang/sdk/issues/63842.
          expectedError:
              "Failed to read the 'x' property from 'Object': "
              "Cannot access 'x' from debugger",
        );
        await driver.checkInFrame(
          breakpointId: 'bp3',
          expression: '_x',
          // See: https://github.com/dart-lang/sdk/issues/63842.
          expectedError:
              "Failed to read the 'x' property from 'Object': "
              "Cannot access 'x' from debugger",
        );
      });
    });
    group('paused in constructor body', () {
      test('conventional public named parameter', () async {
        await driver.checkInFrame(
          breakpointId: 'bp2',
          expression: 'x',
          expectedResult: 'hello',
        );
        await driver.checkInFrame(
          breakpointId: 'bp2',
          expression: '_x',
          expectedResult: 'hello',
        );
      });
      test('private named parameter', () async {
        await driver.checkInFrame(
          breakpointId: 'bp4',
          expression: 'x',
          expectedResult: '99',
        );
        await driver.checkInFrame(
          breakpointId: 'bp4',
          expression: '_x',
          expectedResult: 'goodbye',
        );
      });
    });
  });
}
