// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dev_compiler/src/compiler/module_builder.dart'
    show ModuleFormat;
import 'package:test/test.dart';

import 'expression_compiler_e2e_suite.dart';
import 'setup_compiler_options.dart';

void main(List<String> args) async {
  var driver = await TestDriver.init();

  group('Dart 2.17 language features', () {
    tearDownAll(() async {
      await driver.finish();
    });

    group('(Unsound null safety)', () {
      group('(AMD module system)', () {
        var setup = SetupCompilerOptions(
          soundNullSafety: false,
          legacyCode: false,
          moduleFormat: ModuleFormat.amd,
          args: args,
        );
        runSharedTests(setup, driver);
      });

      group('(DDC module system)', () {
        var setup = SetupCompilerOptions(
          soundNullSafety: false,
          legacyCode: false,
          moduleFormat: ModuleFormat.ddc,
          args: args,
        );
        runSharedTests(setup, driver);
      });
    });

    group('(Sound null safety)', () {
      group('(AMD module system)', () {
        var setup = SetupCompilerOptions(
          soundNullSafety: true,
          legacyCode: false,
          moduleFormat: ModuleFormat.amd,
          args: args,
        );
        runSharedTests(setup, driver);
      });

      group('(DDC module system)', () {
        var setup = SetupCompilerOptions(
          soundNullSafety: true,
          legacyCode: false,
          moduleFormat: ModuleFormat.ddc,
          args: args,
        );
        runSharedTests(setup, driver);
      });
    });
  });
}

/// Shared tests for language features introduced in version 2.17.0.
void runSharedTests(SetupCompilerOptions setup, TestDriver driver) {
  group('Named arguments anywhere', () {
    var source = r'''
      String topLevelMethod(int param1, String param2,
              {int param3 = -1, String param4 = 'default'}) =>
          '$param1, $param2, $param3, $param4';

      class C {
        int param1;
        String param2;
        int param3;
        String param4;
        C(this.param1, this.param2,
            {this.param3 = -1, this.param4 = 'default'});

        static String staticMethod(int param1, String param2,
              {int param3 = -1, String param4 = 'default'}) =>
          '$param1, $param2, $param3, $param4';

        String instanceMethod(int param1, String param2,
              {int param3 = -1, String param4 = 'default'}) =>
          '$param1, $param2, $param3, $param4';

        String toString() => '$param1, $param2, $param3, $param4';
      }

      main() {
        String localMethod(int param1, String param2,
              {int param3 = -1, String param4 = 'default'}) =>
          '$param1, $param2, $param3, $param4';
        var c = C(1, 'two');
        // Breakpoint: bp
        print('hello world');
      }
        ''';

    setUpAll(() async {
      await driver.initSource(setup, source, experiments: const {});
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('in top level method', () async {
      await driver.check(
          breakpointId: 'bp',
          expression: 'topLevelMethod(param3: 3, 1, param4: "four", "two")',
          expectedResult: '1, two, 3, four');
    });
    test('in local method', () async {
      await driver.check(
          breakpointId: 'bp',
          expression: 'topLevelMethod(param3: 3, 1, param4: "four", "two")',
          expectedResult: '1, two, 3, four');
    });
    test('in class constructor', () async {
      await driver.check(
          breakpointId: 'bp',
          expression: 'C(param3: 3, 1, param4: "four", "two").toString()',
          expectedResult: '1, two, 3, four');
    });
    test('in class static method', () async {
      await driver.check(
          breakpointId: 'bp',
          expression: 'C.staticMethod(param3: 3, 1, param4: "four", "two")',
          expectedResult: '1, two, 3, four');
    });
    test('in class instance method', () async {
      await driver.check(
          breakpointId: 'bp',
          expression: 'c.instanceMethod(param3: 3, 1, param4: "four", "two")',
          expectedResult: '1, two, 3, four');
    });
  });

  group('Super parameters', () {
    var source = r'''
      class S {
        final int i;
        final String? s;
        final double d;

        S(this.i, [this.s]): d = 3.14;

        S.named(this.i, {this.d = 3.14}): s = 'default';
      }

      class C extends S {
        final int i1;
        final int i2;

        C(this.i1, super.i, this.i2, [super.s]);

        C.named({super.d}): i1 = 10, i2 = 30, super.named(20);
      }

      main() {
        var c = C(1, 2, 3, 'bar');
        var c2 = C.named(d: 2.71);
        // Breakpoint: bp
        print('hello world');
      }
        ''';

    setUpAll(() async {
      await driver.initSource(setup, source, experiments: const {});
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('in constructor mixed with regular parameters', () async {
      await driver.check(
          breakpointId: 'bp', expression: 'c.i1', expectedResult: '1');
      await driver.check(
          breakpointId: 'bp', expression: 'c.i', expectedResult: '2');
      await driver.check(
          breakpointId: 'bp', expression: 'c.i2', expectedResult: '3');
      await driver.check(
          breakpointId: 'bp', expression: 'c.s', expectedResult: 'bar');
      await driver.check(
          breakpointId: 'bp', expression: 'c.d', expectedResult: '3.14');
    });
    test('in named constructor mixed with regular parameters', () async {
      await driver.check(
          breakpointId: 'bp', expression: 'c2.i1', expectedResult: '10');
      await driver.check(
          breakpointId: 'bp', expression: 'c2.i', expectedResult: '20');
      await driver.check(
          breakpointId: 'bp', expression: 'c2.i2', expectedResult: '30');
      await driver.check(
          breakpointId: 'bp', expression: 'c2.s', expectedResult: 'default');
      await driver.check(
          breakpointId: 'bp', expression: 'c2.d', expectedResult: '2.71');
    });
  });

  group('Enhanced enums', () {
    var source = r'''
      enum E<T> with M {
        id_int<int>(0),
        id_bool<bool>(true),
        id_string<String>('hello world', n: 13);

        final T field;
        final num n;
        static const constStaticField = id_string;

        const E(T arg0, {num? n}) : this.field = arg0, this.n = n ?? 42;

        T get fieldGetter => field;
        num instanceMethod() => n;
      }

      enum E2 with M {
        v1, v2, id_string;
      }

      mixin M on Enum {
        int mixinMethod() => index * 100;
      }

      main() {
        var e = E.id_string;
        // Breakpoint: bp
        print('hello world');
      }
        ''';

    setUpAll(() async {
      await driver.initSource(setup, source, experiments: const {});
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('evaluate to the correct string', () async {
      await driver.check(
          breakpointId: 'bp',
          expression: 'E.id_string.toString()',
          expectedResult: 'E.id_string');
    });
    test('evaluate to the correct index', () async {
      await driver.check(
          breakpointId: 'bp',
          expression: 'E.id_string.index',
          expectedResult: '2');
    });
    test('compare properly against themselves', () async {
      await driver.check(
          breakpointId: 'bp',
          expression: 'e == E.id_string && E.id_string == E.id_string',
          expectedResult: 'true');
    });
    test('compare properly against other enums', () async {
      await driver.check(
          breakpointId: 'bp',
          expression: 'e != E2.id_string && E.id_string != E2.id_string',
          expectedResult: 'true');
    });
    test('with instance methods', () async {
      await driver.check(
          breakpointId: 'bp',
          expression: 'E.id_bool.instanceMethod()',
          expectedResult: '42');
    });
    test('with instance methods from local instance', () async {
      await driver.check(
          breakpointId: 'bp',
          expression: 'e.instanceMethod()',
          expectedResult: '13');
    });
    test('with getters', () async {
      await driver.check(
          breakpointId: 'bp',
          expression: 'E.id_int.fieldGetter',
          expectedResult: '0');
    });
    test('with getters from local instance', () async {
      await driver.check(
          breakpointId: 'bp',
          expression: 'e.fieldGetter',
          expectedResult: 'hello world');
    });
    test('with mixin calls', () async {
      await driver.check(
          breakpointId: 'bp',
          expression: 'E.id_string.mixinMethod()',
          expectedResult: '200');
    });
    test('with mixin calls through overridden indices', () async {
      await driver.check(
          breakpointId: 'bp',
          expression: 'E2.v2.mixinMethod()',
          expectedResult: '100');
    });
  });
}
