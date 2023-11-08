// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dev_compiler/src/compiler/module_builder.dart';
import 'package:test/test.dart';

import '../shared_test_options.dart';
import 'expression_compiler_suite.dart';

void main(List<String> args) {
  for (var moduleFormat in [ModuleFormat.amd, ModuleFormat.ddc]) {
    group('Module format: $moduleFormat |', () {
      group('Unsound null safety |', () {
        runTests(SetupCompilerOptions(
          soundNullSafety: false,
          moduleFormat: moduleFormat,
          args: args,
        ));
      });
    });
  }

  for (var moduleFormat in [ModuleFormat.amd, ModuleFormat.ddc]) {
    group('Module format: $moduleFormat |', () {
      group('Sound null safety |', () {
        runTests(SetupCompilerOptions(
          soundNullSafety: true,
          moduleFormat: moduleFormat,
          args: args,
        ));
      });
    });
  }
}

void runTests(SetupCompilerOptions setup) {
  group('Expression compilations on the same expression compiler |', () {
    var source = '''
      main() {
      }

      void foo() {
        // Breakpoint
      }
      ''';

    late ExpressionCompilerTestDriver driver;

    setUp(() {
      driver = ExpressionCompilerTestDriver(setup, source);
    });

    tearDown(() {
      driver.delete();
    });

    test('successful expression compilations', () async {
      var compiler = await driver.createCompiler();
      await driver.check(
          compiler: compiler,
          scope: <String, String>{},
          expression: 'true',
          expectedResult: contains('return true;'));
      await driver.check(
          compiler: compiler,
          scope: <String, String>{},
          expression: 'false',
          expectedResult: contains('return false;'));
    });

    test('some successful expression compilations', () async {
      var compiler = await driver.createCompiler();
      await driver.check(
          compiler: compiler,
          scope: <String, String>{},
          expression: 'true',
          expectedResult: contains('return true;'));
      await driver.check(
        compiler: compiler,
        scope: <String, String>{},
        expression: 'blah',
        expectedError: "Undefined name 'blah'",
      );
      await driver.check(
          compiler: compiler,
          scope: <String, String>{},
          expression: 'false',
          expectedResult: contains('return false;'));
    });

    test('failing expression compilations', () async {
      var compiler = await driver.createCompiler();
      await driver.check(
        compiler: compiler,
        scope: <String, String>{},
        expression: 'blah1',
        expectedError: "Undefined name 'blah1'",
      );
      await driver.check(
        compiler: compiler,
        scope: <String, String>{},
        expression: 'blah2',
        expectedError: "Undefined name 'blah2'",
      );
    });
  });

  group('Expression compiler import tests', () {
    var source = '''
      import 'dart:io' show Directory;
      import 'dart:io' as p;
      import 'dart:convert' as p;

      main() {
        print(Directory.systemTemp);
        print(p.Directory.systemTemp);
        print(p.utf8.decoder);
      }

      void foo() {
        // Breakpoint
      }
      ''';

    late ExpressionCompilerTestDriver driver;

    setUp(() {
      driver = ExpressionCompilerTestDriver(setup, source);
    });

    tearDown(() {
      driver.delete();
    });

    test('expression referencing unnamed import', () async {
      await driver.check(
          scope: <String, String>{},
          expression: 'Directory.systemTemp',
          expectedResult: contains('return io.Directory.systemTemp;'));
    });

    test('expression referencing named import', () async {
      await driver.check(
          scope: <String, String>{},
          expression: 'p.Directory.systemTemp',
          expectedResult: contains('return io.Directory.systemTemp;'));
    });

    test('expression referencing another library with the same named import',
        () async {
      await driver.check(
          scope: <String, String>{},
          expression: 'p.utf8.decoder',
          expectedResult: contains('return convert.utf8.decoder;'));
    });
  });
}
