// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, File;

import 'package:test/test.dart';

import '../shared_test_options.dart';
import 'test_compiler.dart';

class ExpressionCompilerTestDriver {
  final SetupCompilerOptions setup;
  late Directory testDir;
  String source;
  late Uri input;
  late Uri output;
  late Uri packages;
  late int line;

  ExpressionCompilerTestDriver(this.setup, this.source) {
    source = '${setup.dartLangComment}\n\n$source';
    line = _getEvaluationLine(source);
    var systemTempDir = Directory.systemTemp;
    testDir = systemTempDir.createTempSync('foo bar');

    output = testDir.uri.resolve('test.js');
    input = testDir.uri.resolve('test.dart');
    File.fromUri(input)
      ..createSync()
      ..writeAsStringSync(source);

    packages = testDir.uri.resolve('package_config.json');
    File.fromUri(packages)
      ..createSync()
      ..writeAsStringSync('''
      {
        "configVersion": 2,
        "packages": [
          {
            "name": "foo",
            "rootUri": "./",
            "packageUri": "./"
          }
        ]
      }
      ''');
  }

  void delete() {
    testDir.deleteSync(recursive: true);
  }

  Future<TestExpressionCompiler> createCompiler() =>
      TestExpressionCompiler.init(setup,
          input: input, output: output, packages: packages);

  Future<TestCompilationResult> compile({
    required TestExpressionCompiler compiler,
    required Map<String, String> scope,
    required String expression,
  }) async {
    return compiler.compileExpression(
        input: input,
        line: line,
        column: 1,
        scope: scope,
        expression: expression);
  }

  void checkResult(
    TestCompilationResult result, {
    String? expectedError,
    dynamic expectedResult,
  }) {
    var success = expectedError == null;
    var message = success ? expectedResult! : expectedError;

    expect(
        result,
        const TypeMatcher<TestCompilationResult>()
            .having((r) => r.result!, 'result', _matches(message))
            .having((r) => r.isSuccess, 'isSuccess', success));
  }

  Future<void> check({
    TestExpressionCompiler? compiler,
    required Map<String, String> scope,
    required String expression,
    String? expectedError,
    dynamic expectedResult,
  }) async {
    compiler ??= await createCompiler();
    var result =
        await compile(compiler: compiler, scope: scope, expression: expression);

    checkResult(result,
        expectedError: expectedError, expectedResult: expectedResult);
  }

  Matcher _matches(dynamic matcher) {
    if (matcher is Matcher) return matcher;
    if (matcher is! String) throw StateError('Unsupported matcher $matcher');

    var unIndented = RegExp.escape(matcher).replaceAll(RegExp('[ ]+'), '[ ]*');
    return matches(RegExp(unIndented, multiLine: true));
  }

  static int _getEvaluationLine(String source) {
    var placeholderRegExp = RegExp(r'// Breakpoint');

    var lines = source.split('\n');
    for (var line = 0; line < lines.length; line++) {
      var content = lines[line];
      if (placeholderRegExp.firstMatch(content) != null) {
        return line + 1;
      }
    }
    return -1;
  }
}
