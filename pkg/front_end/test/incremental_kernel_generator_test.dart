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

typedef void LibraryChecker(Library lib);

@reflectiveTest
class IncrementalKernelGeneratorTest {
  static final sdkSummaryUri = Uri.parse('special:sdk_summary');

  /// Virtual filesystem for testing.
  final fileSystem = new MemoryFileSystem(pathos.posix, Uri.parse('file:///'));

  /// The object under test.
  IncrementalKernelGenerator incrementalKernelGenerator;

  void checkLibraries(
      List<Library> libraries, Map<Uri, LibraryChecker> expected) {
    expect(
        libraries.map((lib) => lib.importUri), unorderedEquals(expected.keys));
    var librariesMap = <Uri, Library>{};
    for (var lib in libraries) {
      librariesMap[lib.importUri] = lib;
    }
    expected.forEach((uri, checker) => checker(librariesMap[uri]));
  }

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
    // TODO(paulberry): test parts.
    writeFiles({'/foo.dart': 'main() { print(1); }'});
    var fileUri = Uri.parse('file:///foo.dart');
    var initialState = await getInitialState(fileUri);
    expect(initialState.keys, unorderedEquals([fileUri]));
    void _checkMain(List<Library> libraries, int expectedArgument) {
      checkLibraries(libraries, {
        fileUri: (library) {
          expect(library.importUri, fileUri);
          expect(library.classes, isEmpty);
          expect(library.procedures, hasLength(1));
          expect(library.procedures[0].name.name, 'main');
          var body = library.procedures[0].function.body;
          expect(body, new isInstanceOf<Block>());
          var block = body as Block;
          expect(block.statements, hasLength(1));
          expect(block.statements[0], new isInstanceOf<ExpressionStatement>());
          var expressionStatement = block.statements[0] as ExpressionStatement;
          expect(expressionStatement.expression,
              new isInstanceOf<StaticInvocation>());
          var staticInvocation =
              expressionStatement.expression as StaticInvocation;
          expect(staticInvocation.target.name.name, 'print');
          expect(staticInvocation.arguments.positional, hasLength(1));
          expect(staticInvocation.arguments.positional[0],
              new isInstanceOf<IntLiteral>());
          var intLiteral =
              staticInvocation.arguments.positional[0] as IntLiteral;
          expect(intLiteral.value, expectedArgument);
        },
        Uri.parse('dart:core'): (library) {
          // Should contain the procedure "print" but not its definition.
          expect(library.procedures, hasLength(1));
          expect(library.procedures[0].name.name, 'print');
          expect(library.procedures[0].function.body, isNull);
        }
      });
    }

    _checkMain(initialState[fileUri].libraries, 1);
    writeFiles({'/foo.dart': 'main() { print(2); }'});
    incrementalKernelGenerator.invalidateAll();
    var deltaProgram = await incrementalKernelGenerator.computeDelta();
    expect(deltaProgram.newState.keys, unorderedEquals([fileUri]));
    _checkMain(deltaProgram.newState[fileUri].libraries, 2);
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
