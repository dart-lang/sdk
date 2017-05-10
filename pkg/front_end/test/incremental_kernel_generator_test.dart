// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:front_end/compiler_options.dart';
import 'package:front_end/incremental_kernel_generator.dart';
import 'package:front_end/memory_file_system.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'src/incremental/mock_sdk.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IncrementalKernelGeneratorTest);
  });
}

@reflectiveTest
class IncrementalKernelGeneratorTest {
  /// Virtual filesystem for testing.
  final fileSystem = new MemoryFileSystem(Uri.parse('file:///'));

  /// The object under test.
  IncrementalKernelGenerator incrementalKernelGenerator;

  /// Compute the initial [Program] for the given [entryPoint].
  Future<Program> getInitialState(Uri entryPoint) async {
    Map<String, Uri> dartLibraries = createSdkFiles(fileSystem);
    // TODO(scheglov) Builder the SDK kernel and set it into the options.

    // TODO(scheglov) Make `.packages` file optional.

    var compilerOptions = new CompilerOptions()
      ..fileSystem = fileSystem
      ..strongMode = true
      ..chaseDependencies = true
      ..dartLibraries = dartLibraries
      ..packagesFileUri = Uri.parse('file:///test/.packages');
    incrementalKernelGenerator = await IncrementalKernelGenerator.newInstance(
        compilerOptions, entryPoint);
    return (await incrementalKernelGenerator.computeDelta()).newProgram;
  }

  test_updateEntryPoint() async {
    writeFile('/test/.packages', 'test:lib/');
    String path = '/test/lib/test.dart';
    Uri uri = writeFile(
        path,
        r'''
main() {
  var v = 1;
}
''');

    String initialText = r'''
library;
import self as self;
import "dart:core" as core;

static method main() → dynamic {
  core::int v = 1;
}
''';

    // Compute the initial state.
    {
      Program program = await getInitialState(uri);
      Library library = _getLibrary(program, uri);
      expect(_getLibraryText(library), initialText);
    }

    // Update the entry point library.
    writeFile(
        path,
        r'''
main() {
  var v = 2.3;
}
''');

    // Because we have not invalidated the file, we get the same library.
    // TODO(scheglov) Eventually we should get an empty Program.
    {
      DeltaProgram delta = await incrementalKernelGenerator.computeDelta();
      Library library = _getLibrary(delta.newProgram, uri);
      expect(_getLibraryText(library), initialText);
    }

    // Invalidate the file, so get the new text.
    incrementalKernelGenerator.invalidate(uri);
    {
      DeltaProgram delta = await incrementalKernelGenerator.computeDelta();
      Library library = _getLibrary(delta.newProgram, uri);
      expect(
          _getLibraryText(library),
          r'''
library;
import self as self;
import "dart:core" as core;

static method main() → dynamic {
  core::double v = 2.3;
}
''');
    }
  }

  /// Write the given [text] of the file with the given [path] into the
  /// virtual filesystem.  Return the URI of the file.
  Uri writeFile(String path, String text) {
    Uri uri = Uri.parse('file://$path');
    fileSystem.entityForUri(uri).writeAsStringSync(text);
    return uri;
  }

//  test_part() async {
//    writeFiles({
//      '/foo.dart': 'library foo; part "bar.dart"; main() { print(1); f(); }',
//      '/bar.dart': 'part of foo; f() { print(2); }'
//    });
//    var fooUri = Uri.parse('file:///foo.dart');
//    var initialState = await getInitialState(fooUri);
//    expect(initialState.keys, unorderedEquals([fooUri]));
//    var library = _getLibrary(initialState[fooUri], fooUri);
//    var mainStatements =
//        _getProcedureStatements(_getProcedure(library, 'main'));
//    var fProcedure = _getProcedure(library, 'f');
//    var fStatements = _getProcedureStatements(fProcedure);
//    expect(mainStatements, hasLength(2));
//    _checkPrintLiteralInt(mainStatements[0], 1);
//    _checkFunctionCall(mainStatements[1], fProcedure);
//    expect(fStatements, hasLength(1));
//    _checkPrintLiteralInt(fStatements[0], 2);
//     TODO(paulberry): now test incremental updates
//  }

  /// Write the given file contents to the virtual filesystem.
  void writeFiles(Map<String, String> contents) {
    contents.forEach(writeFile);
  }

  Library _getLibrary(Program program, Uri uri) {
    for (var library in program.libraries) {
      if (library.importUri == uri) return library;
    }
    throw fail('No library found with URI "$uri"');
  }

  String _getLibraryText(Library library) {
    StringBuffer buffer = new StringBuffer();
    new Printer(buffer, syntheticNames: new NameSystem())
        .writeLibraryFile(library);
    return buffer.toString();
  }
}
