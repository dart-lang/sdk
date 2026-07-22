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
final i = 'Fosse';
final _i = 'Cello';
final s = 2;
final _s = 123;
''';

const source = '''

// Breakpoint: bp1
class C(final String s, {required final int i}) {
  this {
    // Breakpoint: bp2
    print('from C constructor body');
  }
}

// Breakpoint: bp3
class C2(final String _s, {required final int _i}) {
  this {
    // Breakpoint: bp4
    print('from C2 constructor body');
  }
}

void main() {
  C('hello', i: 99);
  C2('goodbye', i: 42);
}
''';

void main(List<String> args) async {
  var driver = await ExpressionEvaluationTestDriver.init();

  group('Dart 3.13 language features', () {
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

/// Shared tests for language features introduced in version 3.13.0.
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
    group(
      'paused at primary constructor definition',
      () {
        test('public declaring positional parameter', () async {
          await driver.checkInFrame(
            breakpointId: 'bp1',
            expression: 's',
            expectedResult: '???',
          );
        });
        test('public declaring named parameter', () async {
          await driver.checkInFrame(
            breakpointId: 'bp1',
            expression: 'i',
            expectedResult: '???',
          );
        });
        test('private declaring positional parameter', () async {
          await driver.checkInFrame(
            breakpointId: 'bp3',
            expression: '_s',
            expectedResult: '???',
          );
        });
        test('private declaring named parameter', () async {
          await driver.checkInFrame(
            breakpointId: 'bp3',
            expression: '_i',
            expectedResult: '???',
          );
        });
      },
      // See: https://github.com/dart-lang/sdk/issues/63861
      skip: true,
    );
    group('paused in primary constructor body', () {
      test('public declaring positional parameter', () async {
        await driver.checkInFrame(
          breakpointId: 'bp2',
          expression: 's',
          expectedResult: 'hello',
        );
        await driver.checkInFrame(
          breakpointId: 'bp2',
          expression: 'this.s',
          expectedResult: 'hello',
        );
      });
      test('public declaring named parameter', () async {
        await driver.checkInFrame(
          breakpointId: 'bp2',
          expression: 'i',
          expectedResult: '99',
        );
        await driver.checkInFrame(
          breakpointId: 'bp2',
          expression: 'this.i',
          expectedResult: '99',
        );
      });
      test('private declaring positional parameter', () async {
        await driver.checkInFrame(
          breakpointId: 'bp4',
          expression: '_s',
          expectedResult: 'goodbye',
        );
        await driver.checkInFrame(
          breakpointId: 'bp4',
          expression: 'this._s',
          expectedResult: 'goodbye',
        );
        await driver.checkInFrame(
          breakpointId: 'bp4',
          expression: 's',
          // See: https://github.com/dart-lang/sdk/issues/63842.
          expectedError:
              "DartError: NoSuchMethodError: 's'\n"
              'method not found\n'
              "Receiver: Instance of 'C2'\n"
              'Arguments: []\n',
        );
      });
      test('private declaring named parameter', () async {
        await driver.checkInFrame(
          breakpointId: 'bp4',
          expression: '_i',
          expectedResult: '42',
        );
        await driver.checkInFrame(
          breakpointId: 'bp4',
          expression: 'this._i',
          expectedResult: '42',
        );
        await driver.checkInFrame(
          breakpointId: 'bp4',
          expression: 'i',
          // See: https://github.com/dart-lang/sdk/issues/63842.
          expectedError:
              "DartError: NoSuchMethodError: 'i'\n"
              'method not found\n'
              "Receiver: Instance of 'C2'\n"
              'Arguments: []\n',
        );
      });
    });
  });

  group('With top-level name conflicts', () {
    setUpAll(() async {
      await driver.initSource(
        setup,
        '$conflictingTopLevelFieldsSource\n'
        '$source',
      );
    });
    tearDownAll(() async {
      await driver.cleanupTest();
    });
    group(
      'paused at primary constructor definition',
      () {
        test('public declaring positional parameter', () async {
          await driver.checkInFrame(
            breakpointId: 'bp1',
            expression: 's',
            expectedResult: '???',
          );
        });
        test('public declaring named parameter', () async {
          await driver.checkInFrame(
            breakpointId: 'bp1',
            expression: 'i',
            expectedResult: '???',
          );
        });
        test('private declaring positional parameter', () async {
          await driver.checkInFrame(
            breakpointId: 'bp3',
            expression: '_s',
            expectedResult: '???',
          );
        });
        test('private declaring named parameter', () async {
          await driver.checkInFrame(
            breakpointId: 'bp3',
            expression: '_i',
            expectedResult: '???',
          );
        });
      },
      // https://github.com/dart-lang/sdk/issues/63861
      skip: true,
    );
    group('paused in primary constructor body', () {
      test('public declaring positional parameter', () async {
        await driver.checkInFrame(
          breakpointId: 'bp2',
          expression: 's',
          expectedResult: 'hello',
        );
        await driver.checkInFrame(
          breakpointId: 'bp2',
          expression: 'this.s',
          expectedResult: 'hello',
        );
      });
      test('public declaring named parameter', () async {
        await driver.checkInFrame(
          breakpointId: 'bp2',
          expression: 'i',
          expectedResult: '99',
        );
        await driver.checkInFrame(
          breakpointId: 'bp2',
          expression: 'this.i',
          expectedResult: '99',
        );
      });
      test('private declaring positional parameter', () async {
        await driver.checkInFrame(
          breakpointId: 'bp4',
          expression: '_s',
          expectedResult: 'goodbye',
        );
        await driver.checkInFrame(
          breakpointId: 'bp4',
          expression: 'this._s',
          expectedResult: 'goodbye',
        );
        await driver.checkInFrame(
          breakpointId: 'bp4',
          expression: 's',
          expectedResult: '2',
        );
      });
      test('private declaring named parameter', () async {
        await driver.checkInFrame(
          breakpointId: 'bp4',
          expression: '_i',
          expectedResult: '42',
        );
        await driver.checkInFrame(
          breakpointId: 'bp4',
          expression: 'this._i',
          expectedResult: '42',
        );
        await driver.checkInFrame(
          breakpointId: 'bp4',
          expression: 'i',
          expectedResult: 'Fosse',
        );
      });
    });
  });
}
