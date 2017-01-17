// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
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

  test_emptyProgram() async {
    writeFiles({'/foo.dart': 'main() {}'});
    var fooUri = Uri.parse('file:///foo.dart');
    var initialProgram = await getInitialProgram(fooUri);
    expect(initialProgram.keys, unorderedEquals([fooUri]));
    var unit = initialProgram[fooUri].definingCompilationUnit;
    expect(unit.declarations, hasLength(1));
    expect(unit.declarations[0], new isInstanceOf<FunctionDeclaration>());
    var main = unit.declarations[0] as FunctionDeclaration;
    expect(main.name.name, 'main');
    // TODO(paulberry): test that stuff is actually resolved.
    // TODO(paulberry): test parts.
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
