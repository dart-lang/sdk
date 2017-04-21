// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:front_end/compiler_options.dart';
import 'package:front_end/incremental_resolved_ast_generator.dart';
import 'package:front_end/memory_file_system.dart';
import 'package:path/path.dart' as pathos;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IncrementalResolvedAstGeneratorTest);
  });
}

final _sdkSummary = _readSdkSummary();

List<int> _readSdkSummary() {
  var resourceProvider = PhysicalResourceProvider.INSTANCE;
  var sdk = new FolderBasedDartSdk(resourceProvider,
      FolderBasedDartSdk.defaultSdkDirectory(resourceProvider))
    ..useSummary = true;
  var path = resourceProvider.pathContext
      .join(sdk.directory.path, 'lib', '_internal', 'strong.sum');
  return resourceProvider.getFile(path).readAsBytesSync();
}

@reflectiveTest
class IncrementalResolvedAstGeneratorTest {
  static final sdkSummaryUri = Uri.parse('special:sdk_summary');

  /// Virtual filesystem for testing.
  final fileSystem = new MemoryFileSystem(pathos.posix, Uri.parse('file:///'));

  /// The object under test.
  IncrementalResolvedAstGenerator incrementalResolvedAstGenerator;

  Future<Map<Uri, Map<Uri, CompilationUnit>>> getInitialProgram(
      Uri startingUri) async {
    fileSystem.entityForUri(sdkSummaryUri).writeAsBytesSync(_sdkSummary);
    incrementalResolvedAstGenerator = new IncrementalResolvedAstGenerator(
        startingUri,
        new CompilerOptions()
          ..fileSystem = fileSystem
          ..chaseDependencies = true
          ..sdkSummary = sdkSummaryUri
          ..packagesFileUri = new Uri());
    return (await incrementalResolvedAstGenerator.computeDelta()).newState;
  }

  test_incrementalUpdate_referenceToCore() async {
    writeFiles({'/foo.dart': 'main() { print(1); }'});
    var fooUri = Uri.parse('file:///foo.dart');
    var initialProgram = await getInitialProgram(fooUri);
    expect(initialProgram.keys, unorderedEquals([fooUri]));

    void _checkMain(CompilationUnit unit, int expectedArgument) {
      var mainStatements = _getFunctionStatements(_getFunction(unit, 'main'));
      expect(mainStatements, hasLength(1));
      _checkPrintLiteralInt(mainStatements[0], expectedArgument);
    }

    _checkMain(initialProgram[fooUri][fooUri], 1);
    writeFiles({'/foo.dart': 'main() { print(2); }'});
    // Verify that the file isn't actually reread until invalidate is called.
    var deltaProgram1 = await incrementalResolvedAstGenerator.computeDelta();
    // TODO(paulberry): since there is no delta, computeDelta should return an
    // empty map.
    // expect(deltaProgram1.newState, isEmpty);
    expect(deltaProgram1.newState.keys, unorderedEquals([fooUri]));
    _checkMain(deltaProgram1.newState[fooUri][fooUri], 1);
    incrementalResolvedAstGenerator.invalidateAll();
    var deltaProgram2 = await incrementalResolvedAstGenerator.computeDelta();
    expect(deltaProgram2.newState.keys, unorderedEquals([fooUri]));
    _checkMain(deltaProgram2.newState[fooUri][fooUri], 2);
  }

  test_invalidateAllBeforeInitialProgram() async {
    incrementalResolvedAstGenerator = new IncrementalResolvedAstGenerator(
        Uri.parse('file:///foo.dart'),
        new CompilerOptions()
          ..fileSystem = fileSystem
          ..chaseDependencies = true
          ..packagesFileUri = new Uri());
    incrementalResolvedAstGenerator.invalidateAll();
  }

  test_part() async {
    writeFiles({
      '/foo.dart': 'library foo; part "bar.dart"; main() { print(1); f(); }',
      '/bar.dart': 'part of foo; f() { print(2); }'
    });
    var fooUri = Uri.parse('file:///foo.dart');
    var barUri = Uri.parse('file:///bar.dart');
    var initialProgram = await getInitialProgram(fooUri);
    expect(initialProgram.keys, unorderedEquals([fooUri]));
    expect(initialProgram[fooUri].keys, unorderedEquals([fooUri, barUri]));
    var mainStatements = _getFunctionStatements(
        _getFunction(initialProgram[fooUri][fooUri], 'main'));
    var fDeclaration = _getFunction(initialProgram[fooUri][barUri], 'f');
    var fStatements = _getFunctionStatements(fDeclaration);
    expect(mainStatements, hasLength(2));
    _checkPrintLiteralInt(mainStatements[0], 1);
    _checkFunctionCall(mainStatements[1],
        resolutionMap.elementDeclaredByFunctionDeclaration(fDeclaration));
    expect(fStatements, hasLength(1));
    _checkPrintLiteralInt(fStatements[0], 2);
    // TODO(paulberry): now test incremental updates
  }

  /// Write the given file contents to the virtual filesystem.
  void writeFiles(Map<String, String> contents) {
    contents.forEach((path, text) {
      fileSystem
          .entityForUri(Uri.parse('file://$path'))
          .writeAsStringSync(text);
    });
  }

  void _checkFunctionCall(Statement statement, Element expectedTarget) {
    expect(statement, new isInstanceOf<ExpressionStatement>());
    var expressionStatement = statement as ExpressionStatement;
    expect(
        expressionStatement.expression, new isInstanceOf<MethodInvocation>());
    var methodInvocation = expressionStatement.expression as MethodInvocation;
    expect(
        resolutionMap.staticElementForIdentifier(methodInvocation.methodName),
        expectedTarget);
  }

  void _checkPrintLiteralInt(Statement statement, int expectedArgument) {
    expect(statement, new isInstanceOf<ExpressionStatement>());
    var expressionStatement = statement as ExpressionStatement;
    expect(
        expressionStatement.expression, new isInstanceOf<MethodInvocation>());
    var methodInvocation = expressionStatement.expression as MethodInvocation;
    expect(methodInvocation.methodName.name, 'print');
    var printElement =
        resolutionMap.staticElementForIdentifier(methodInvocation.methodName);
    expect(printElement, isNotNull);
    expect(printElement.library.source.uri, Uri.parse('dart:core'));
    expect(methodInvocation.argumentList.arguments, hasLength(1));
    expect(methodInvocation.argumentList.arguments[0],
        new isInstanceOf<IntegerLiteral>());
    var integerLiteral =
        methodInvocation.argumentList.arguments[0] as IntegerLiteral;
    expect(integerLiteral.value, expectedArgument);
  }

  FunctionDeclaration _getFunction(CompilationUnit unit, String name) {
    for (var declaration in unit.declarations) {
      if (declaration is FunctionDeclaration && declaration.name.name == name) {
        return declaration;
      }
    }
    throw fail('No function declaration found with name "$name"');
  }

  NodeList<Statement> _getFunctionStatements(FunctionDeclaration function) {
    var body = function.functionExpression.body;
    expect(body, new isInstanceOf<BlockFunctionBody>());
    return (body as BlockFunctionBody).block.statements;
  }
}
