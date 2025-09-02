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
    const localConstsSource = '''
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
      await driver.initSource(setup, localConstsSource);
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
  group('dot shorthands', () {
    const dotShorthandsSource = '''
    enum Color {
      red,
      green,
      blue;

      int get lengthOfName => name.length;
    }

    class C {
      final int i;
      C(this.i);
      C.namedConstructor() : i = 2;
      const C.constConstructor() : i = 1;
      factory C.factoryConstructor() => C(42);
      static C staticMethod() => C(99);
    }

    String enumContext(Color c) => c.name;

    int classContext(C c) => c.i;

    T genericContext<T>(T val) => val;

    void main() {
      // Breakpoint: bp
      print('hello world');
    }
    ''';

    setUpAll(() async {
      await driver.initSource(setup, dotShorthandsSource);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });
    group('enum context', () {
      test('name', () async {
        await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'enumContext(.red)',
          expectedResult: 'red',
        );
      });
      test('equals method', () async {
        await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'genericContext<bool>(Color.green == .green)',
          expectedResult: 'true',
        );
      });
      test('generic context', () async {
        await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'genericContext<Color>(.blue)',
          expectedResult: 'blue',
        );
      });
    });

    group('class context', () {
      test('new', () async {
        await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'classContext(.new(123))',
          expectedResult: '123',
        );
      });
      test('named constructor', () async {
        await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'classContext(.namedConstructor())',
          expectedResult: '2',
        );
      });
      test('const constructor', () async {
        await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'const <C>[.constConstructor()].single.i',
          expectedResult: '1',
        );
      });
      test('factory constructor', () async {
        await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'classContext(.factoryConstructor())',
          expectedResult: '42',
        );
      });
      test('static method', () async {
        await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'classContext(.staticMethod())',
          expectedResult: '99',
        );
      });
    });
    test('equals method', () async {
      await driver.checkInFrame(
        breakpointId: 'bp',
        expression: 'genericContext<bool>(C(99) == .namedConstructor())',
        expectedResult: 'false',
      );
    });
    test('generic context', () async {
      await driver.checkInFrame(
        breakpointId: 'bp',
        expression: 'genericContext<C>(.namedConstructor()).i',
        expectedResult: '2',
      );
    });
  });
}
