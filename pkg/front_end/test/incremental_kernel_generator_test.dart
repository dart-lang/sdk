// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:front_end/compiler_options.dart';
import 'package:front_end/incremental_kernel_generator.dart';
import 'package:front_end/memory_file_system.dart';
import 'package:front_end/src/byte_store/byte_store.dart';
import 'package:front_end/src/incremental_kernel_generator_impl.dart';
import 'package:front_end/summary_generator.dart';
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

  /// The used file watcher.
  WatchUsedFilesFn watchFn = (uri, used) {};

  /// The object under test.
  IncrementalKernelGeneratorImpl incrementalKernelGenerator;

  /// Compute the initial [Program] for the given [entryPoint].
  Future<Program> getInitialState(Uri entryPoint,
      {Uri sdkOutlineUri, bool setPackages: true}) async {
    createSdkFiles(fileSystem);
    // TODO(scheglov) Builder the SDK kernel and set it into the options.

    var compilerOptions = new CompilerOptions()
      ..fileSystem = fileSystem
      ..byteStore = new MemoryByteStore()
//      ..logger = new PerformanceLog(stdout)
      ..strongMode = true
      ..chaseDependencies = true
      ..librariesSpecificationUri = Uri.parse('file:///sdk/lib/libraries.json')
      ..sdkSummary = sdkOutlineUri;

    if (setPackages) {
      compilerOptions.packagesFileUri = Uri.parse('file:///test/.packages');
    }
    incrementalKernelGenerator = await IncrementalKernelGenerator
        .newInstance(compilerOptions, entryPoint, watch: watchFn);
    return (await incrementalKernelGenerator.computeDelta()).newProgram;
  }

  test_acceptLastDelta() async {
    writeFile('/test/.packages', 'test:lib/');
    String path = '/test/lib/test.dart';
    Uri uri = writeFile(path, 'var v = 1;');

    await getInitialState(uri);
    incrementalKernelGenerator.acceptLastDelta();

    // Attempt to accept the second time.
    expect(() {
      incrementalKernelGenerator.acceptLastDelta();
    }, throwsStateError);
  }

  test_compile_chain() async {
    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    String cPath = '/test/lib/c.dart';
    Uri aUri = writeFile(aPath, 'var a = 1;');
    Uri bUri = writeFile(bPath, r'''
import 'a.dart';
var b = a;
''');
    Uri cUri = writeFile(cPath, r'''
import 'a.dart';
import 'b.dart';
var c1 = a;
var c2 = b;
void main() {}
''');

    {
      Program program = await getInitialState(cUri);
      incrementalKernelGenerator.acceptLastDelta();
      _assertLibraryUris(program,
          includes: [aUri, bUri, cUri, Uri.parse('dart:core')]);
      Library library = _getLibrary(program, cUri);
      expect(_getLibraryText(library), r'''
library;
import self as self;
import "dart:core" as core;
import "./a.dart" as a;
import "./b.dart" as b;

static field core::int c1 = a::a;
static field core::int c2 = b::b;
static method main() → void {}
''');
      // The main method is set.
      expect(program.mainMethod, isNotNull);
      expect(program.mainMethod.enclosingLibrary.fileUri, cUri.toString());
    }

    // Update b.dart and recompile c.dart
    writeFile(bPath, r'''
import 'a.dart';
var b = 1.2;
''');
    incrementalKernelGenerator.invalidate(bUri);
    {
      DeltaProgram delta = await incrementalKernelGenerator.computeDelta();
      Program program = delta.newProgram;
      _assertLibraryUris(program,
          includes: [bUri, cUri], excludes: [aUri, Uri.parse('dart:core')]);
      Library library = _getLibrary(program, cUri);
      expect(_getLibraryText(library), r'''
library;
import self as self;
import "dart:core" as core;
import "./a.dart" as a;
import "./b.dart" as b;

static field core::int c1 = a::a;
static field core::double c2 = b::b;
static method main() → void {}
''');
      // The main method is set even though not the entry point is updated.
      expect(program.mainMethod, isNotNull);
      expect(program.mainMethod.enclosingLibrary.fileUri, cUri.toString());
    }
  }

  test_compile_includePathToMain() async {
    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    String cPath = '/test/lib/c.dart';
    String dPath = '/test/lib/d.dart';

    // A --> B -> C
    //   \-> D

    Uri aUri = writeFile(aPath, r'''
import 'b.dart';
import 'd.dart';
main() {
  b();
  d();
}
''');
    Uri bUri = writeFile(bPath, r'''
import 'c.dart';
b() {
  c();
}
''');
    Uri cUri = writeFile(cPath, 'c() { print(0); }');
    Uri dUri = writeFile(dPath, 'd() {}');

    {
      Program program = await getInitialState(aUri);
      incrementalKernelGenerator.acceptLastDelta();
      _assertLibraryUris(program,
          includes: [aUri, bUri, cUri, dUri, Uri.parse('dart:core')]);
    }

    // Update c.dart and compute the delta.
    // It should include the changed c.dart, plus b.dart and a.dart because VM
    // requires this (because of possible inlining). But d.dart is not on the
    // path from main() to the changed c.dart, so it is not included.
    writeFile(cPath, 'c() { print(1); }');
    incrementalKernelGenerator.invalidate(cUri);
    {
      DeltaProgram delta = await incrementalKernelGenerator.computeDelta();
      incrementalKernelGenerator.acceptLastDelta();
      Program program = delta.newProgram;
      _assertLibraryUris(program,
          includes: [aUri, bUri, cUri],
          excludes: [dUri, Uri.parse('dart:core')]);
      // While a.dart and b.dart are is included (VM needs them), they were not
      // recompiled, because the change to c.dart was in the function body.
      _assertCompiledUris([cUri]);
    }
  }

  test_compile_useSdkOutline() async {
    createSdkFiles(fileSystem);
    List<int> sdkOutlineBytes = await _computeSdkOutlineBytes();

    Uri sdkOutlineUri = Uri.parse('file:///sdk/outline.dill');
    fileSystem.entityForUri(sdkOutlineUri).writeAsBytesSync(sdkOutlineBytes);

    writeFile('/test/.packages', 'test:lib/');
    String path = '/test/lib/test.dart';
    Uri uri = writeFile(path, r'''
import 'dart:async';
var a = 1;
Future<String> b;
''');

    Program program = await getInitialState(uri, sdkOutlineUri: sdkOutlineUri);
    _assertLibraryUris(program,
        includes: [uri], excludes: [Uri.parse('dart:core')]);

    Library library = _getLibrary(program, uri);
    expect(_getLibraryText(library), r'''library;
import self as self;
import "dart:core" as core;
import "dart:async" as asy;

static field core::int a = 1;
static field asy::Future<core::String> b;
''');
  }

  test_inferPackagesFile() async {
    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    writeFile(aPath, 'var a = 1;');
    Uri bUri = writeFile(bPath, r'''
import "package:test/a.dart";
var b = a;
''');

    // Ensures that the `.packages` file can be discovered automatically
    // from the entry point file.
    Program program = await getInitialState(bUri, setPackages: false);
    Library library = _getLibrary(program, bUri);
    expect(_getLibraryText(library), r'''
library;
import self as self;
import "dart:core" as core;
import "package:test/a.dart" as a;

static field core::int b = a::a;
''');
  }

  test_rejectLastDelta() async {
    writeFile('/test/.packages', 'test:lib/');
    String path = '/test/lib/test.dart';
    Uri uri = writeFile(path, 'var v = 1;');

    // The first delta includes the the library.
    {
      Program program = await getInitialState(uri);
      _assertLibraryUris(program, includes: [uri]);
      Library library = _getLibrary(program, uri);
      expect(_getLibraryText(library), contains('core::int v = 1'));
    }

    // Reject the last delta, so the test library is included again.
    incrementalKernelGenerator.rejectLastDelta();
    {
      var delta = await incrementalKernelGenerator.computeDelta();
      Program program = delta.newProgram;
      _assertLibraryUris(program, includes: [uri]);
    }

    // Attempt to reject the last delta twice.
    incrementalKernelGenerator.rejectLastDelta();
    expect(() {
      incrementalKernelGenerator.rejectLastDelta();
    }, throwsStateError);
  }

  test_updateEntryPoint() async {
    writeFile('/test/.packages', 'test:lib/');
    String path = '/test/lib/test.dart';
    Uri uri = writeFile(path, r'''
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
      incrementalKernelGenerator.acceptLastDelta();
      Library library = _getLibrary(program, uri);
      expect(_getLibraryText(library), initialText);
    }

    // Update the entry point library.
    writeFile(path, r'''
main() {
  var v = 2.3;
}
''');

    // We have not invalidated the file, so the delta is empty.
    {
      DeltaProgram delta = await incrementalKernelGenerator.computeDelta();
      incrementalKernelGenerator.acceptLastDelta();
      expect(delta.newProgram.libraries, isEmpty);
    }

    // Invalidate the file, so get the new text.
    incrementalKernelGenerator.invalidate(uri);
    {
      DeltaProgram delta = await incrementalKernelGenerator.computeDelta();
      incrementalKernelGenerator.acceptLastDelta();
      Program program = delta.newProgram;
      _assertLibraryUris(program, includes: [uri]);
      Library library = _getLibrary(program, uri);
      expect(_getLibraryText(library), r'''
library;
import self as self;
import "dart:core" as core;

static method main() → dynamic {
  core::double v = 2.3;
}
''');
    }
  }

  test_watch() async {
    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    String cPath = '/test/lib/c.dart';
    Uri aUri = writeFile(aPath, '');
    Uri bUri = writeFile(bPath, '');
    Uri cUri = writeFile(cPath, r'''
import 'a.dart';
''');

    var usedFiles = <Uri>[];
    var unusedFiles = <Uri>[];
    watchFn = (Uri uri, bool used) {
      if (used) {
        usedFiles.add(uri);
      } else {
        unusedFiles.add(uri);
      }
      return new Future.value();
    };

    {
      await getInitialState(cUri);
      incrementalKernelGenerator.acceptLastDelta();
      // We use at least c.dart and a.dart now.
      expect(usedFiles, contains(cUri));
      expect(usedFiles, contains(aUri));
      usedFiles.clear();
      expect(unusedFiles, isEmpty);
    }

    // Update c.dart to reference also b.dart file.
    writeFile(cPath, r'''
import 'a.dart';
import 'b.dart';
''');
    incrementalKernelGenerator.invalidate(cUri);
    {
      await incrementalKernelGenerator.computeDelta();
      incrementalKernelGenerator.acceptLastDelta();
      // The only new file is b.dart now.
      expect(usedFiles, [bUri]);
      usedFiles.clear();
      expect(unusedFiles, isEmpty);
    }

    // Update c.dart to stop referencing b.dart file.
    writeFile(cPath, r'''
import 'a.dart';
''');
    incrementalKernelGenerator.invalidate(cUri);
    {
      await incrementalKernelGenerator.computeDelta();
      incrementalKernelGenerator.acceptLastDelta();
      // No new used files.
      expect(usedFiles, isEmpty);
      // The file b.dart is not used anymore.
      expect(unusedFiles, [bUri]);
      unusedFiles.clear();
    }
  }

  test_watch_null() async {
    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    writeFile(aPath, "");
    Uri bUri = writeFile(bPath, "");

    // Set null, as if the watch function is not provided.
    watchFn = null;

    await getInitialState(bUri);
    incrementalKernelGenerator.acceptLastDelta();

    // Update b.dart to import a.dart file.
    writeFile(bPath, "import 'a.dart';");
    incrementalKernelGenerator.invalidate(bUri);
    await incrementalKernelGenerator.computeDelta();

    // No exception even though the watcher function is null.
  }

  /// Write the given [text] of the file with the given [path] into the
  /// virtual filesystem.  Return the URI of the file.
  Uri writeFile(String path, String text) {
    Uri uri = Uri.parse('file://$path');
    fileSystem.entityForUri(uri).writeAsStringSync(text);
    return uri;
  }

  /// Write the given file contents to the virtual filesystem.
  void writeFiles(Map<String, String> contents) {
    contents.forEach(writeFile);
  }

  void _assertCompiledUris(Iterable<Uri> expected) {
    var compiledCycles =
        incrementalKernelGenerator.test.driver.test.compiledCycles;
    Set<Uri> compiledUris = compiledCycles
        .map((cycle) => cycle.libraries.map((file) => file.uri))
        .expand((uris) => uris)
        .toSet();
    expect(compiledUris, unorderedEquals(expected));
  }

  void _assertLibraryUris(Program program,
      {List<Uri> includes: const [], List<Uri> excludes: const []}) {
    List<Uri> libraryUris =
        program.libraries.map((library) => library.importUri).toList();
    for (var shouldInclude in includes) {
      expect(libraryUris, contains(shouldInclude));
    }
    for (var shouldExclude in excludes) {
      expect(libraryUris, isNot(contains(shouldExclude)));
    }
  }

  Future<List<int>> _computeSdkOutlineBytes() async {
    var options = new CompilerOptions()
      ..fileSystem = fileSystem
      ..sdkRoot = Uri.parse('file:///sdk/')
      ..compileSdk = true
      ..chaseDependencies = true
      ..strongMode = true;
    var inputs = [Uri.parse('dart:core')];
    return summaryFor(inputs, options);
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
