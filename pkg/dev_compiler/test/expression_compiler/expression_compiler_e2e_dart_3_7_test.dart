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

  group('Dart 3.7 language features', () {
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

/// Shared tests for language features introduced in version 3.7.0.
///
/// Wildcards create local variables in scope that are unused. They should not
/// interfere with expression evaluation in any way.
void runSharedTests(
  SetupCompilerOptions setup,
  ExpressionEvaluationTestDriver driver,
) {
  group('Wildcard', () {
    const recordsSource = '''
    // @dart=3.7
    void main() {
      withWildcardArgument(1, "two");
      withWildcardLocalVariable("hello");
      withWildcardTypeArgument<DateTime, String>("world");
    }

    void withWildcardArgument(int _, String __) {
      var d = Duration(seconds: 3);

      // Breakpoint: bp
      print('hello world');
    }

    void withWildcardLocalVariable(String __) {
      var _ = 99;
      String _ = 'never used';
      var d = Duration(seconds: 3);

      // Breakpoint: bp2
      print('hello world');
    }

    void withWildcardTypeArgument<_, T>(String __) {
      var d = Duration(seconds: 3);

      // Breakpoint: bp3
      print('hello world');
    }
    ''';

    setUpAll(() async {
      await driver.initSource(setup, recordsSource);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('method argument in scope do not break other evaluations', () async {
      await driver.checkInFrame(
        breakpointId: 'bp',
        expression: 'd.toString()',
        expectedResult: '0:00:03.000000',
      );
      await driver.checkInFrame(
        breakpointId: 'bp',
        expression: '__.toString()',
        expectedResult: 'two',
      );
    });

    test('local variable in scope do not break other evaluations', () async {
      await driver.checkInFrame(
        breakpointId: 'bp2',
        expression: 'd.toString()',
        expectedResult: '0:00:03.000000',
      );
      await driver.checkInFrame(
        breakpointId: 'bp2',
        expression: '__.toString()',
        expectedResult: 'hello',
      );
    });

    test('type argument in scope do not break other evaluations', () async {
      await driver.checkInFrame(
        breakpointId: 'bp3',
        expression: 'd.toString()',
        expectedResult: '0:00:03.000000',
      );
      await driver.checkInFrame(
        breakpointId: 'bp3',
        expression: '__.toString()',
        expectedResult: 'world',
      );
      await driver.checkInFrame(
        breakpointId: 'bp3',
        expression: 'T.toString()',
        expectedResult: 'String',
      );
    });
  });

  group('Wildcard in async scope', () {
    const recordsSource = '''
    // @dart=3.7
    Future<void> main() async {
      await withWildcardArgument(1, "two");
      await withWildcardLocalVariable("hello");
      await withWildcardTypeArgument<DateTime, String>("world");
    }

    Future<void> withWildcardArgument(int _, String __) async {
      var d = Duration(seconds: 3);

      // Use the argument in the scope to ensure chrome captures it.
      print(__);

      // Breakpoint: bp
      print('hello world');
    }

    Future<void> withWildcardLocalVariable(String __) async {
      var _ = 99;
      String _ = 'never used';
      var d = Duration(seconds: 3);

      // Use the argument in the scope to ensure chrome captures it.
      print(__);

      // Breakpoint: bp2
      print('hello world');
    }

    Future<void> withWildcardTypeArgument<_, T>(String __) async {
      var d = Duration(seconds: 3);

      // Use the arguments in the scope to ensure chrome captures it.
      print(__);
      print(T);

      // Breakpoint: bp3
      print('hello world');
    }
    ''';

    setUpAll(() async {
      await driver.initSource(setup, recordsSource);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('method argument in scope do not break other evaluations', () async {
      await driver.checkInFrame(
        breakpointId: 'bp',
        expression: 'd.toString()',
        expectedResult: '0:00:03.000000',
      );
      await driver.checkInFrame(
        breakpointId: 'bp',
        expression: '__.toString()',
        expectedResult: 'two',
      );
    });

    test('local variable in scope do not break other evaluations', () async {
      await driver.checkInFrame(
        breakpointId: 'bp2',
        expression: 'd.toString()',
        expectedResult: '0:00:03.000000',
      );
      await driver.checkInFrame(
        breakpointId: 'bp2',
        expression: '__.toString()',
        expectedResult: 'hello',
      );
    });

    test('type argument in scope do not break other evaluations', () async {
      await driver.checkInFrame(
        breakpointId: 'bp3',
        expression: 'd.toString()',
        expectedResult: '0:00:03.000000',
      );
      await driver.checkInFrame(
        breakpointId: 'bp3',
        expression: '__.toString()',
        expectedResult: 'world',
      );
      await driver.checkInFrame(
        breakpointId: 'bp3',
        expression: 'T.toString()',
        expectedResult: 'String',
      );
    });
  });
}
