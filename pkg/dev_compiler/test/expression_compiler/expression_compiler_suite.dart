// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, File;

import 'package:test/test.dart';

import '../shared_test_options.dart';
import 'test_compiler.dart';

typedef AdditionalLibrary = ({String name, String source});

class ExpressionCompilerTestDriver {
  final SetupCompilerOptions setup;
  late Directory _testRootDirectory;
  String source;
  late Uri input;
  late Uri output;
  late Uri packages;
  late int line;
  final List<AdditionalLibrary> additionalLibraries;

  ExpressionCompilerTestDriver(
    this.setup,
    this.source, {
    this.additionalLibraries = const [],
  }) {
    line = _getEvaluationLine(source);
    var systemTempDir = Directory.systemTemp;
    _testRootDirectory = systemTempDir.createTempSync('expression_eval_test');
    var testPackageDirectory = Directory.fromUri(
      _testRootDirectory.uri.resolve('test_package/'),
    );

    output = testPackageDirectory.uri.resolve('test.js');
    input = testPackageDirectory.uri.resolve('test.dart');
    File.fromUri(input)
      ..createSync(recursive: true)
      ..writeAsStringSync(source);

    packages = _testRootDirectory.uri.resolve('package_config.json');
    var packageDescriptors = [_createPackageDescriptor('test_package')];
    for (var library in additionalLibraries) {
      var name = library.name;
      var source = library.source;
      var additionalPackageDirectory = Directory.fromUri(
        _testRootDirectory.uri.resolve('$name/'),
      );
      var additionalFile = additionalPackageDirectory.uri.resolve('$name.dart');
      File.fromUri(additionalFile)
        ..createSync(recursive: true)
        ..writeAsStringSync(source);
      packageDescriptors.add(_createPackageDescriptor(name));
    }
    File.fromUri(packages)
      ..createSync()
      ..writeAsStringSync('''
      {
        "configVersion": 2,
        "packages": [
          ${packageDescriptors.join(',\n          ')}
        ]
      }
      ''');
  }

  /// Creates a `packages_config.json` entry for a test package called [name].
  static String _createPackageDescriptor(String name) =>
      '''{
            "name": "$name",
            "rootUri": "./$name",
            "packageUri": "./"
          }''';

  void delete() {
    _testRootDirectory.deleteSync(recursive: true);
  }

  Future<TestExpressionCompiler> createCompiler() =>
      TestExpressionCompiler.init(
        setup,
        input: input,
        output: output,
        packages: packages,
      );

  Future<TestCompilationResult> compile({
    required TestExpressionCompiler compiler,
    required Map<String, String> scope,
    required String expression,
  }) async {
    return compiler.compileExpression(
      libraryUri: input,
      line: line,
      column: 1,
      scope: scope,
      expression: expression,
    );
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
          .having((r) => r.isSuccess, 'isSuccess', success),
    );
  }

  Future<void> check({
    TestExpressionCompiler? compiler,
    required Map<String, String> scope,
    required String expression,
    String? expectedError,
    dynamic expectedResult,
  }) async {
    compiler ??= await createCompiler();
    var result = await compile(
      compiler: compiler,
      scope: scope,
      expression: expression,
    );

    checkResult(
      result,
      expectedError: expectedError,
      expectedResult: expectedResult,
    );
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
