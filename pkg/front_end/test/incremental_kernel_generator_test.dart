// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:front_end/compiler_options.dart';
import 'package:front_end/incremental_kernel_generator.dart';
import 'package:front_end/memory_file_system.dart';
import 'package:kernel/ast.dart';
import 'package:path/path.dart' as pathos;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IncrementalKernelGeneratorTest);
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
class IncrementalKernelGeneratorTest {
  static final sdkSummaryUri = Uri.parse('special:sdk_summary');

  /// Virtual filesystem for testing.
  final fileSystem = new MemoryFileSystem(pathos.posix, Uri.parse('file:///'));

  /// The object under test.
  IncrementalKernelGenerator incrementalKernelGenerator;

  Future<Map<Uri, Program>> getInitialState(Uri startingUri) async {
    fileSystem.entityForUri(sdkSummaryUri).writeAsBytesSync(_sdkSummary);
    incrementalKernelGenerator = new IncrementalKernelGenerator(
        startingUri,
        new CompilerOptions()
          ..fileSystem = fileSystem
          ..chaseDependencies = true
          ..sdkSummary = sdkSummaryUri
          ..packagesFileUri = new Uri());
    return (await incrementalKernelGenerator.computeDelta()).newState;
  }

  test_incrementalUpdate_referenceToCore() async {
    writeFiles({'/foo.dart': 'main() { print(1); }'});
    var fooUri = Uri.parse('file:///foo.dart');
    var coreUri = Uri.parse('dart:core');
    var initialState = await getInitialState(fooUri);
    expect(initialState.keys, unorderedEquals([fooUri]));

    void _checkMain(Program program, int expectedArgument) {
      expect(_getLibraryUris(program), unorderedEquals([fooUri, coreUri]));
      var mainStatements = _getProcedureStatements(
          _getProcedure(_getLibrary(program, fooUri), 'main'));
      expect(mainStatements, hasLength(1));
      _checkPrintLiteralInt(mainStatements[0], expectedArgument);
      var coreLibrary = _getLibrary(program, coreUri);
      expect(coreLibrary.procedures, hasLength(1));
      expect(coreLibrary.procedures[0].name.name, 'print');
      expect(coreLibrary.procedures[0].function.body, isNull);
    }

    _checkMain(initialState[fooUri], 1);
    writeFiles({'/foo.dart': 'main() { print(2); }'});
    incrementalKernelGenerator.invalidateAll();
    var deltaProgram = await incrementalKernelGenerator.computeDelta();
    expect(deltaProgram.newState.keys, unorderedEquals([fooUri]));
    _checkMain(deltaProgram.newState[fooUri], 2);
  }

  test_part() async {
    writeFiles({
      '/foo.dart': 'library foo; part "bar.dart"; main() { print(1); f(); }',
      '/bar.dart': 'part of foo; f() { print(2); }'
    });
    var fooUri = Uri.parse('file:///foo.dart');
    var initialState = await getInitialState(fooUri);
    expect(initialState.keys, unorderedEquals([fooUri]));
    var library = _getLibrary(initialState[fooUri], fooUri);
    var mainStatements =
        _getProcedureStatements(_getProcedure(library, 'main'));
    var fProcedure = _getProcedure(library, 'f');
    var fStatements = _getProcedureStatements(fProcedure);
    expect(mainStatements, hasLength(2));
    _checkPrintLiteralInt(mainStatements[0], 1);
    _checkFunctionCall(mainStatements[1], fProcedure);
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

  void _checkFunctionCall(Statement statement, Procedure expectedTarget) {
    expect(statement, new isInstanceOf<ExpressionStatement>());
    var expressionStatement = statement as ExpressionStatement;
    expect(
        expressionStatement.expression, new isInstanceOf<StaticInvocation>());
    var staticInvocation = expressionStatement.expression as StaticInvocation;
    expect(staticInvocation.target, same(expectedTarget));
  }

  void _checkPrintLiteralInt(Statement statement, int expectedArgument) {
    expect(statement, new isInstanceOf<ExpressionStatement>());
    var expressionStatement = statement as ExpressionStatement;
    expect(
        expressionStatement.expression, new isInstanceOf<StaticInvocation>());
    var staticInvocation = expressionStatement.expression as StaticInvocation;
    expect(staticInvocation.target.name.name, 'print');
    expect(staticInvocation.arguments.positional, hasLength(1));
    expect(staticInvocation.arguments.positional[0],
        new isInstanceOf<IntLiteral>());
    var intLiteral = staticInvocation.arguments.positional[0] as IntLiteral;
    expect(intLiteral.value, expectedArgument);
  }

  Library _getLibrary(Program program, Uri uri) {
    for (var library in program.libraries) {
      if (library.importUri == uri) return library;
    }
    throw fail('No library found with URI "$uri"');
  }

  List<Uri> _getLibraryUris(Program program) =>
      program.libraries.map((library) => library.importUri).toList();

  Procedure _getProcedure(Library library, String name) {
    for (var procedure in library.procedures) {
      if (procedure.name.name == name) return procedure;
    }
    throw fail('No function declaration found with name "$name"');
  }

  List<Statement> _getProcedureStatements(Procedure procedure) {
    var body = procedure.function.body;
    expect(body, new isInstanceOf<Block>());
    return (body as Block).statements;
  }
}
