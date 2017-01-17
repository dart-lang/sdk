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

  test_emptyProgram() async {
    writeFiles({'/foo.dart': 'main() {}'});
    var fileUri = Uri.parse('file:///foo.dart');
    var initialState = await getInitialState(fileUri);
    expect(initialState.keys, unorderedEquals([fileUri]));
    var program = initialState[fileUri];
    expect(program.libraries, hasLength(1));
    var library = program.libraries[0];
    expect(library.importUri, fileUri);
    expect(library.classes, isEmpty);
    expect(library.procedures, hasLength(1));
    expect(library.procedures[0].name.name, 'main');
    var body = library.procedures[0].function.body;
    expect(body, new isInstanceOf<Block>());
    var block = body as Block;
    expect(block.statements, isEmpty);
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
