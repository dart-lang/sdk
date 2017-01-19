// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
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

  Future<Map<Uri, ResolvedLibrary>> getInitialProgram(Uri startingUri) async {
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
    // TODO(paulberry): test parts.
    writeFiles({'/foo.dart': 'main() { print(1); }'});
    var fooUri = Uri.parse('file:///foo.dart');
    var initialProgram = await getInitialProgram(fooUri);
    expect(initialProgram.keys, unorderedEquals([fooUri]));

    void _checkMain(CompilationUnit unit, int expectedArgument) {
      expect(unit.declarations, hasLength(1));
      expect(unit.declarations[0], new isInstanceOf<FunctionDeclaration>());
      var main = unit.declarations[0] as FunctionDeclaration;
      expect(main.name.name, 'main');
      expect(
          main.functionExpression.body, new isInstanceOf<BlockFunctionBody>());
      var blockFunctionBody = main.functionExpression.body as BlockFunctionBody;
      expect(blockFunctionBody.block.statements, hasLength(1));
      expect(blockFunctionBody.block.statements[0],
          new isInstanceOf<ExpressionStatement>());
      var expressionStatement =
          blockFunctionBody.block.statements[0] as ExpressionStatement;
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

    _checkMain(initialProgram[fooUri].definingCompilationUnit, 1);
    writeFiles({'/foo.dart': 'main() { print(2); }'});
    // TODO(paulberry): verify that the file isn't actually reread until
    // invalidate is called.
    // var deltaProgram1 = await incrementalResolvedAstGenerator.computeDelta();
    // expect(deltaProgram1.newState, isEmpty);
    incrementalResolvedAstGenerator.invalidateAll();
    var deltaProgram2 = await incrementalResolvedAstGenerator.computeDelta();
    expect(deltaProgram2.newState.keys, unorderedEquals([fooUri]));
    _checkMain(deltaProgram2.newState[fooUri].definingCompilationUnit, 2);
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

  /// Write the given file contents to the virtual filesystem.
  void writeFiles(Map<String, String> contents) {
    contents.forEach((path, text) {
      fileSystem
          .entityForUri(Uri.parse('file://$path'))
          .writeAsStringSync(text);
    });
  }
}
