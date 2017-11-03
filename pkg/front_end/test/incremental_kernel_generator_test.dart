// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:front_end/byte_store.dart';
import 'package:front_end/compiler_options.dart';
import 'package:front_end/incremental_kernel_generator.dart';
import 'package:front_end/memory_file_system.dart';
import 'package:front_end/src/byte_store/protected_file_byte_store.dart';
import 'package:front_end/src/fasta/kernel/utils.dart';
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
  final fileSystem = new MemoryFileSystem(Uri.parse('org-dartlang-test:///'));

  /// The used file watcher.
  WatchUsedFilesFn watchFn = (uri, used) {};

  /// The object under test.
  IncrementalKernelGeneratorImpl incrementalKernelGenerator;

  /// Compute the initial [Program] for the given [entryPoint].
  Future<DeltaProgram> getInitialState(Uri entryPoint,
      {Uri sdkOutlineUri,
      bool setPackages: true,
      bool embedSourceText: true,
      String initialState,
      ByteStore byteStore}) async {
    createSdkFiles(fileSystem);
    // TODO(scheglov) Builder the SDK kernel and set it into the options.

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

    incrementalKernelGenerator = await IncrementalKernelGenerator
        .newInstance(compilerOptions, entryPoint, watch: watchFn);

    if (initialState != null) {
      incrementalKernelGenerator.setState(initialState);
    }

    return await incrementalKernelGenerator.computeDelta();
  }

  test_acceptLastDelta() async {
    writeFile('/test/.packages', 'test:lib/');
    String path = '/test/lib/test.dart';
    Uri uri = writeFile(path, '');

    await getInitialState(uri);
    incrementalKernelGenerator.acceptLastDelta();

    // Attempt to accept the second time.
    _assertStateError(() {
      incrementalKernelGenerator.acceptLastDelta();
    }, IncrementalKernelGeneratorImpl.MSG_NO_LAST_DELTA);
  }

  test_acceptLastDelta_protectedFileByteStore() async {
    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    Uri aUri = writeFile(aPath, 'var a = 1;');
    Uri bUri = writeFile(bPath, r'''
import 'a.dart';
var b = a;
''');

    var byteStore = new _ProtectedFileByteStoreMock();

    {
      await getInitialState(bUri, byteStore: byteStore);
      incrementalKernelGenerator.acceptLastDelta();

      // There is nothing to remove yet.
      expect(byteStore.removedKeys, isEmpty);

      // The added keys: SDK, a.dart, and b.dart
      expect(byteStore.addedKeys, hasLength(3));

      byteStore.clearState();
    }

    // Update b.dart and recompile.
    writeFile(bPath, r'''
import 'a.dart';
var b = a + 1;
''');
    incrementalKernelGenerator.invalidate(bUri);
    {
      await incrementalKernelGenerator.computeDelta();
      incrementalKernelGenerator.acceptLastDelta();

      // The key for b.dart should be removed.
      // But we don't actually check the key.
      expect(byteStore.removedKeys, hasLength(1));

      // The new key for b.dart should be added.
      expect(byteStore.addedKeys, hasLength(1));
    }

    // Update a.dart and recompile.
    writeFile(aPath, 'var a = 2;');
    incrementalKernelGenerator.invalidate(aUri);
    {
      await incrementalKernelGenerator.computeDelta();
      incrementalKernelGenerator.acceptLastDelta();

      // The keys for a.dart and b.dart should be removed.
      expect(byteStore.removedKeys, hasLength(2));

      // The new keys for a.dart and b.dart should be added.
      expect(byteStore.addedKeys, hasLength(2));
    }
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
      DeltaProgram delta = await getInitialState(aUri);
      Program program = delta.newProgram;
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
    incrementalKernelGenerator.acceptLastDelta();
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
    incrementalKernelGenerator.invalidate(aUri);
    var deltaProgram = await incrementalKernelGenerator.computeDelta();

    // Check that the canonical names for SDK libraries are serializable.
    serializeProgram(deltaProgram.newProgram,
        filter: (library) => !library.importUri.isScheme('dart'));
  }

  test_computeDelta_hasAnotherRunning() async {
    writeFile('/test/.packages', 'test:lib/');
    String path = '/test/lib/test.dart';
    Uri uri = writeFile(path, '');

    await getInitialState(uri);
    incrementalKernelGenerator.acceptLastDelta();

    // Run, but don't wait.
    var future = incrementalKernelGenerator.computeDelta();

    // acceptLastDelta() is failing while the future is pending.
    _assertStateError(() {
      incrementalKernelGenerator.acceptLastDelta();
    }, IncrementalKernelGeneratorImpl.MSG_PENDING_COMPUTE);

    // rejectLastDelta() is failing while the future is pending.
    _assertStateError(() {
      incrementalKernelGenerator.rejectLastDelta();
    }, IncrementalKernelGeneratorImpl.MSG_PENDING_COMPUTE);

    // Run another, this causes StateError.
    _assertStateError(() {
      incrementalKernelGenerator.computeDelta();
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
    incrementalKernelGenerator.rejectLastDelta();
    {
      var delta = await incrementalKernelGenerator.computeDelta();
      Program program = delta.newProgram;
      _assertLibraryUris(program, includes: [uri]);
    }

    // Attempt to reject the last delta twice.
    incrementalKernelGenerator.rejectLastDelta();
    _assertStateError(() {
      incrementalKernelGenerator.rejectLastDelta();
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
    incrementalKernelGenerator.acceptLastDelta();
    {
      var delta = await incrementalKernelGenerator.computeDelta();
      expect(delta.newProgram.libraries, isEmpty);
    }

    // Reset the generator, so it will resend the whole program.
    incrementalKernelGenerator.reset();
    {
      var delta = await incrementalKernelGenerator.computeDelta();
      Program program = delta.newProgram;
      _assertLibraryUris(program, includes: [uri]);
    }
  }

  test_setState() async {
    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    String cPath = '/test/lib/c.dart';
    Uri aUri = writeFile(aPath, 'var a = 1;');
    Uri bUri = writeFile(bPath, r'''
var b = 1;
''');
    Uri cUri = writeFile(cPath, r'''
import 'a.dart';
import 'b.dart';
var c1 = a;
var c2 = b;
''');

    String initialState;
    {
      DeltaProgram delta = await getInitialState(cUri);
      Program program = delta.newProgram;
      incrementalKernelGenerator.acceptLastDelta();
      _assertLibraryUris(program,
          includes: [aUri, bUri, cUri, Uri.parse('dart:core')]);
      initialState = delta.state;
    }

    // Update a.dart, don't notify the old generator - we throw it away.
    writeFile(aPath, 'var a = 1.2');

    // Create a new generator with the initial state.
    var delta = await getInitialState(cUri, initialState: initialState);

    // Only a.dart and c.dart are in the delta.
    // The state of b.dart is the same as in the initial state.
    _assertLibraryUris(delta.newProgram,
        includes: [aUri, cUri], excludes: [bUri, Uri.parse('dart:core')]);
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
    Uri uri = Uri.parse('org-dartlang-test://$path');
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
      var shouldIncludeFileUri = _resolveUriToFileUri(shouldInclude);
      expect(program.uriToSource.keys, contains(shouldIncludeFileUri));
    }
    for (var shouldExclude in excludes) {
      expect(libraryUris, isNot(contains(shouldExclude)));
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
    var translator = incrementalKernelGenerator.test.driver.uriTranslator;
    var outputUri = translator.translate(inputUri) ?? inputUri;
    return outputUri.toString();
  }
}

class _ProtectedFileByteStoreMock implements ProtectedFileByteStore {
  final byteStore = new MemoryByteStore();

  List<String> addedKeys;
  List<String> removedKeys;

  void clearState() {
    addedKeys = null;
    removedKeys = null;
  }

  @override
  void flush() {}

  @override
  List<int> get(String key) {
    return byteStore.get(key);
  }

  @override
  void put(String key, List<int> bytes) {
    byteStore.put(key, bytes);
  }

  @override
  void updateProtectedKeys({List<String> add, List<String> remove}) {
    this.addedKeys = add;
    this.removedKeys = remove;
  }
}
