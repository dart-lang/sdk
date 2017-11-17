// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:front_end/byte_store.dart';
import 'package:front_end/compiler_options.dart';
import 'package:front_end/incremental_kernel_generator.dart';
import 'package:front_end/memory_file_system.dart';
import 'package:front_end/src/fasta/kernel/utils.dart';
import 'package:front_end/src/incremental_kernel_generator_impl.dart';
import 'package:front_end/src/minimal_incremental_kernel_generator.dart';
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
  final fileSystem = new MemoryFileSystem(Uri.parse('org-dartlang-test:///'));

  /// The used file watcher.
  WatchUsedFilesFn watchFn = (uri, used) {};

  /// The object under test.
  MinimalIncrementalKernelGenerator generator;

  /// Compute the initial [Program] for the given [entryPoint].
  Future<DeltaProgram> getInitialState(Uri entryPoint,
      {Uri sdkOutlineUri,
      bool setPackages: true,
      bool embedSourceText: true,
      String initialState,
      ByteStore byteStore}) async {
    createSdkFiles(fileSystem);

    var compilerOptions = new CompilerOptions()
      ..fileSystem = fileSystem
      ..byteStore = byteStore ?? new MemoryByteStore()
//      ..logger = new PerformanceLog(stdout)
      ..strongMode = true
      ..chaseDependencies = true
      ..librariesSpecificationUri =
          Uri.parse('org-dartlang-test:///sdk/lib/libraries.json')
      ..sdkSummary = sdkOutlineUri
      ..embedSourceText = embedSourceText;

    if (setPackages) {
      compilerOptions.packagesFileUri =
          Uri.parse('org-dartlang-test:///test/.packages');
    }

    generator = await IncrementalKernelGenerator.newInstance(
        compilerOptions, entryPoint,
        watch: watchFn, useMinimalGenerator: true);

    if (initialState != null) {
      generator.setState(initialState);
    }

    return await generator.computeDelta();
  }

  test_acceptLastDelta() async {
    writeFile('/test/.packages', 'test:lib/');
    String path = '/test/lib/test.dart';
    Uri uri = writeFile(path, '');

    await getInitialState(uri);
    generator.acceptLastDelta();

    // Attempt to accept the second time.
    _assertStateError(() {
      generator.acceptLastDelta();
    }, IncrementalKernelGeneratorImpl.MSG_NO_LAST_DELTA);
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
      DeltaProgram delta = await getInitialState(cUri);
      Program program = delta.newProgram;
      generator.acceptLastDelta();
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
    generator.invalidate(bUri);
    {
      DeltaProgram delta = await generator.computeDelta();
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
      DeltaProgram delta = await getInitialState(aUri);
      Program program = delta.newProgram;
      generator.acceptLastDelta();
      _assertLibraryUris(program,
          includes: [aUri, bUri, cUri, dUri, Uri.parse('dart:core')]);
    }

    // Update c.dart and compute the delta.
    // It should include the changed c.dart, plus b.dart and a.dart because VM
    // requires this (because of possible inlining). But d.dart is not on the
    // path from main() to the changed c.dart, so it is not included.
    writeFile(cPath, 'c() { print(1); }');
    generator.invalidate(cUri);
    {
      DeltaProgram delta = await generator.computeDelta();
      generator.acceptLastDelta();
      Program program = delta.newProgram;
      _assertLibraryUris(program,
          includes: [aUri, bUri, cUri],
          excludes: [dUri, Uri.parse('dart:core')]);
      // This implementation of IKG invalidates all dirty files.
      // So, when c.dart is invalidated, a.dart and b.dart also compiled.
      _assertCompiledUris([aUri, bUri, cUri]);
    }
  }

  test_compile_parts() async {
    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    Uri aUri = writeFile(aPath, r'''
library lib;
part 'b.dart';
''');
    Uri bUri = writeFile(bPath, r'''
part of lib;
''');

    DeltaProgram delta = await getInitialState(aUri);
    Program program = delta.newProgram;

    // Sources for library and its part must be present.
    expect(program.uriToSource.keys, contains(aUri.toString()));
    expect(program.uriToSource.keys, contains(bUri.toString()));
  }

  test_compile_update_part() async {
    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    String cPath = '/test/lib/c.dart';
    Uri aUri = writeFile(aPath, r'''
library lib;
part 'b.dart';
''');
    Uri bUri = writeFile(bPath, r'''
part of lib;
var b = 1;
''');
    Uri cUri = writeFile(cPath, r'''
import 'a.dart';
''');

    {
      DeltaProgram delta = await getInitialState(cUri);
      generator.acceptLastDelta();
      Program program = delta.newProgram;
      _assertLibraryUris(program,
          includes: [aUri, cUri, Uri.parse('dart:core')]);
      expect(generator.test.compiledUris, contains(aUri));
      expect(generator.test.compiledUris, contains(cUri));
    }

    // Update b.dart (which is a part) and recompile.
    // Both libraries a.dart and c.dart are recompiled.
    writeFile(bPath, r'''
part of lib;
var b = 1.2;
''');
    generator.invalidate(bUri);
    {
      DeltaProgram delta = await generator.computeDelta();
      _assertCompiledUris([aUri, cUri]);
      Program program = delta.newProgram;
      // a.dart and c.dart are included as libraries.
      // b.dart is excluded because it is not a library.
      // All a.dart, b.dart, and c.dart are included in sources.
      _assertLibraryUris(program,
          includes: [aUri, cUri],
          includesSource: [aUri, bUri, cUri],
          excludes: [bUri, Uri.parse('dart:core')],
          excludesSource: [Uri.parse('dart:core')]);
    }
  }

  test_compile_useSdkOutline() async {
    createSdkFiles(fileSystem);
    List<int> sdkOutlineBytes = await _computeSdkOutlineBytes();

    Uri sdkOutlineUri = Uri.parse('org-dartlang-test:///sdk/outline.dill');
    fileSystem.entityForUri(sdkOutlineUri).writeAsBytesSync(sdkOutlineBytes);

    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    Uri aUri = writeFile(aPath, r'''
int getValue() {
  return 1;
}
''');
    Uri bUri = writeFile(bPath, r'''
import 'dart:async';
import 'a.dart';

var a = 1;
Future<String> b;
''');

    DeltaProgram delta =
        await getInitialState(bUri, sdkOutlineUri: sdkOutlineUri);
    Program program = delta.newProgram;
    generator.acceptLastDelta();
    _assertLibraryUris(program,
        includes: [bUri], excludes: [Uri.parse('dart:core')]);

    Library library = _getLibrary(program, bUri);
    expect(_getLibraryText(library), r'''
library;
import self as self;
import "dart:core" as core;
import "dart:async" as asy;

static field core::int a = 1;
static field asy::Future<core::String> b;
''');

    // Update a.dart and recompile.
    writeFile(aPath, r'''
int getValue() {
  return 2;
}
''');
    generator.invalidate(aUri);
    var deltaProgram = await generator.computeDelta();

    // Check that the canonical names for SDK libraries are serializable.
    serializeProgram(deltaProgram.newProgram,
        filter: (library) => !library.importUri.isScheme('dart'));
  }

  test_computeDelta_hasAnotherRunning() async {
    writeFile('/test/.packages', 'test:lib/');
    String path = '/test/lib/test.dart';
    Uri uri = writeFile(path, '');

    await getInitialState(uri);
    generator.acceptLastDelta();

    // Run, but don't wait.
    var future = generator.computeDelta();

    // acceptLastDelta() is failing while the future is pending.
    _assertStateError(() {
      generator.acceptLastDelta();
    }, IncrementalKernelGeneratorImpl.MSG_PENDING_COMPUTE);

    // rejectLastDelta() is failing while the future is pending.
    _assertStateError(() {
      generator.rejectLastDelta();
    }, IncrementalKernelGeneratorImpl.MSG_PENDING_COMPUTE);

    // Run another, this causes StateError.
    _assertStateError(() {
      generator.computeDelta();
    }, IncrementalKernelGeneratorImpl.MSG_PENDING_COMPUTE);

    // Wait for the pending future.
    await future;
  }

  test_embedSourceText_false() async {
    writeFile('/test/.packages', 'test:lib/');
    String path = '/test/lib/test.dart';
    Uri uri = writeFile(path, 'main() {}');

    DeltaProgram delta = await getInitialState(uri, embedSourceText: false);
    Program program = delta.newProgram;

    // The Source object is present in the map, but is empty.
    Source source = program.uriToSource[uri.toString()];
    expect(source, isNotNull);
    expect(source.source, isEmpty);
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
    DeltaProgram delta = await getInitialState(bUri, setPackages: false);
    Program program = delta.newProgram;
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
      DeltaProgram delta = await getInitialState(uri);
      Program program = delta.newProgram;
      _assertLibraryUris(program, includes: [uri]);
      Library library = _getLibrary(program, uri);
      expect(_getLibraryText(library), contains('core::int v = 1'));
    }

    // Reject the last delta, so the test library is included again.
    generator.rejectLastDelta();
    {
      var delta = await generator.computeDelta();
      Program program = delta.newProgram;
      _assertLibraryUris(program, includes: [uri]);
    }

    // Attempt to reject the last delta twice.
    generator.rejectLastDelta();
    _assertStateError(() {
      generator.rejectLastDelta();
    }, IncrementalKernelGeneratorImpl.MSG_NO_LAST_DELTA);
  }

  test_reset() async {
    writeFile('/test/.packages', 'test:lib/');
    String path = '/test/lib/test.dart';
    Uri uri = writeFile(path, 'var v = 1;');

    // The first delta includes the the library.
    {
      DeltaProgram delta = await getInitialState(uri);
      Program program = delta.newProgram;
      _assertLibraryUris(program, includes: [uri]);
      Library library = _getLibrary(program, uri);
      expect(_getLibraryText(library), contains('core::int v = 1'));
    }

    // Accept the last delta, the new delta is empty.
    generator.acceptLastDelta();
    {
      var delta = await generator.computeDelta();
      expect(delta.newProgram.libraries, isEmpty);
    }

    // Reset the generator, so it will resend the whole program.
    generator.reset();
    {
      var delta = await generator.computeDelta();
      Program program = delta.newProgram;
      _assertLibraryUris(program, includes: [uri]);
    }
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
      DeltaProgram delta = await getInitialState(uri);
      Program program = delta.newProgram;
      generator.acceptLastDelta();
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
      DeltaProgram delta = await generator.computeDelta();
      generator.acceptLastDelta();
      expect(delta.newProgram.libraries, isEmpty);
    }

    // Invalidate the file, so get the new text.
    generator.invalidate(uri);
    {
      DeltaProgram delta = await generator.computeDelta();
      generator.acceptLastDelta();
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
      generator.acceptLastDelta();
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
    generator.invalidate(cUri);
    {
      await generator.computeDelta();
      generator.acceptLastDelta();
      // The only new file is b.dart now.
      expect(usedFiles, [bUri]);
      usedFiles.clear();
      expect(unusedFiles, isEmpty);
    }

    // Update c.dart to stop referencing b.dart file.
    writeFile(cPath, r'''
import 'a.dart';
''');
    generator.invalidate(cUri);
    {
      await generator.computeDelta();
      generator.acceptLastDelta();
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
    generator.acceptLastDelta();

    // Update b.dart to import a.dart file.
    writeFile(bPath, "import 'a.dart';");
    generator.invalidate(bUri);
    await generator.computeDelta();

    // No exception even though the watcher function is null.
  }

  /// Write the given [text] of the file with the given [path] into the
  /// virtual filesystem.  Return the URI of the file.
  Uri writeFile(String path, String text) {
    Uri uri = Uri.parse('org-dartlang-test://$path');
    fileSystem.entityForUri(uri).writeAsStringSync(text);
    return uri;
  }

  /// Write the given file contents to the virtual filesystem.
  void writeFiles(Map<String, String> contents) {
    contents.forEach(writeFile);
  }

  void _assertCompiledUris(Iterable<Uri> expected) {
    Set<Uri> compiledUris = generator.test.compiledUris;
    expect(compiledUris, unorderedEquals(expected));
  }

  void _assertLibraryUris(Program program,
      {List<Uri> includes: const [],
      List<Uri> includesSource,
      List<Uri> excludes: const [],
      List<Uri> excludesSource}) {
    List<Uri> libraryUris =
        program.libraries.map((library) => library.importUri).toList();

    for (var shouldInclude in includes) {
      expect(libraryUris, contains(shouldInclude));
    }
    includesSource ??= includes;
    for (var shouldInclude in includes) {
      var shouldIncludeFileUri = _resolveUriToFileUri(shouldInclude);
      expect(program.uriToSource.keys, contains(shouldIncludeFileUri));
    }

    for (var shouldExclude in excludes) {
      expect(libraryUris, isNot(contains(shouldExclude)));
    }
    excludesSource ??= excludes;
    for (var shouldExclude in excludesSource) {
      var shouldExcludeFileUri = _resolveUriToFileUri(shouldExclude);
      expect(program.uriToSource.keys, isNot(contains(shouldExcludeFileUri)));
    }
  }

  /// Assert that invocation of [f] throws a [StateError] with the given [msg].
  void _assertStateError(f(), String msg) {
    try {
      f();
      fail('StateError expected.');
    } on StateError catch (e) {
      expect(e.message, msg);
    }
  }

  Future<List<int>> _computeSdkOutlineBytes() async {
    var options = new CompilerOptions()
      ..fileSystem = fileSystem
      ..sdkRoot = Uri.parse('org-dartlang-test:///sdk/')
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

  /// Resolve the given `dart` or `package` [inputUri] into the corresponding
  /// file URI, or return the same URI if it is already a file URI.
  String _resolveUriToFileUri(Uri inputUri) {
    var translator = generator.uriTranslator;
    var outputUri = translator.translate(inputUri) ?? inputUri;
    return outputUri.toString();
  }
}
