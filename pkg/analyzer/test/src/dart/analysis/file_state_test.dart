// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/analysis_options_map.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/feature_set_provider.dart';
import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/unlinked_unit_store.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart'
    show DartUriResolver, SourceFactory, UriResolver;
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/workspace/basic.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/context_collection_resolution.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FileSystemStateTest);
    defineReflectiveTests(FileSystemState_BlazeWorkspaceTest);
    defineReflectiveTests(FileSystemState_PubPackageTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class FileSystemState_BlazeWorkspaceTest extends BlazeWorkspaceResolutionTest {
  void test_getFileForUri_hasGenerated_askGeneratedFirst() async {
    var relPath = 'dart/my/test/a.dart';
    var writablePath = convertPath('$workspaceRootPath/$relPath');
    var generatedPath = convertPath('$workspaceRootPath/blaze-bin/$relPath');

    // This generated file should be used instead of the writable.
    newFile(generatedPath, '');

    var analysisDriver = driverFor(testFile);

    var fsState = analysisDriver.fsState;

    // Prepare URI(s).
    var generatedUri = toUri(generatedPath);
    var writableUri = toUri(writablePath);

    // The file is the generated file.
    var generatedFile = fsState.getFileForUri(generatedUri).file;
    expect(generatedFile.uri, writableUri);
    expect(generatedFile.path, generatedPath);

    // The file is cached under the requested URI.
    var writableFile1 = fsState.getFileForUri(writableUri).file;
    var writableFile2 = fsState.getFileForUri(writableUri).file;
    expect(writableFile1, same(generatedFile));
    expect(writableFile2, same(generatedFile));
  }

  void test_getFileForUri_hasGenerated_askWritableFirst() async {
    var relPath = 'dart/my/test/a.dart';
    var writablePath = convertPath('$workspaceRootPath/$relPath');
    var generatedPath = convertPath('$workspaceRootPath/blaze-bin/$relPath');

    // This generated file should be used instead of the writable.
    newFile(generatedPath, '');

    var analysisDriver = driverFor(testFile);

    var fsState = analysisDriver.fsState;

    // Prepare URI(s).
    var generatedUri = toUri(generatedPath);
    var writableUri = toUri(writablePath);

    // The file is cached under the requested URI.
    var writableFile1 = fsState.getFileForUri(writableUri).file;
    var writableFile2 = fsState.getFileForUri(writableUri).file;
    expect(writableFile2, same(writableFile1));

    // The file is the generated file.
    var generatedFile = fsState.getFileForUri(generatedUri).file;
    expect(generatedFile.uri, writableUri);
    expect(generatedFile.path, generatedPath);
    expect(writableFile2, same(generatedFile));
  }

  void test_getFileForUri_nestedLib_notCanonicalUri() async {
    var outer = getFile('$workspaceRootPath/my/outer/lib/a.dart');
    var outerUri = Uri.parse('package:my.outer/a.dart');

    var inner = getFile('/workspace/my/outer/lib/inner/lib/b.dart');
    var innerUri = Uri.parse('package:my.outer.lib.inner/b.dart');

    var analysisDriver = driverFor(outer);
    var fsState = analysisDriver.fsState;

    // User code might use such relative URI.
    var innerUri2 = outerUri.resolve('inner/lib/b.dart');
    expect(innerUri2, Uri.parse('package:my.outer/inner/lib/b.dart'));

    // However the returned file must use the canonical URI.
    var innerFile = fsState.getFileForUri(innerUri2).file;
    expect(innerFile.path, inner.path);
    expect(innerFile.uri, innerUri);
  }
}

@reflectiveTest
class FileSystemState_PubPackageTest extends PubPackageResolutionTest {
  @override
  bool get retainDataForTesting => true;

  FileState fileStateFor(File file) {
    return fsStateFor(file).getFileForPath(file.path);
  }

  FileState fileStateForUri(Uri uri) {
    return fsStateFor(testFile).getFileForUri(uri).file;
  }

  FileState fileStateForUriStr(String uriStr) {
    var uri = Uri.parse(uriStr);
    return fileStateForUri(uri);
  }

  FileSystemState fsStateFor(File file) {
    return driverFor(file).fsState;
  }

  test_libraryCycle() {
    var a = newFile('$testPackageLibPath/a.dart', '');
    var b = newFile('$testPackageLibPath/b.dart', '');
    var c = newFile('$testPackageLibPath/c.dart', '');
    var d = newFile('$testPackageLibPath/d.dart', '');

    fileStateFor(a);
    fileStateFor(b);
    fileStateFor(c);
    fileStateFor(d);

    // No imports, individual library cycles.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_4 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_4 dart:core synthetic
        fileKinds: library_1
        cycle_1
          dependencies: dart:core
          libraries: library_1
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_4 dart:core synthetic
        fileKinds: library_2
        cycle_2
          dependencies: dart:core
          libraries: library_2
          apiSignature_2
      unlinkedKey: k00
  /home/test/lib/d.dart
    uri: package:test/d.dart
    current
      id: file_3
      kind: library_3
        libraryImports
          library_4 dart:core synthetic
        fileKinds: library_3
        cycle_3
          dependencies: dart:core
          libraries: library_3
          apiSignature_3
      unlinkedKey: k00
libraryCycles
elementFactory
''');

    // Import `b.dart` into `a.dart`, two files now.
    newFile(a.path, r'''
import 'b.dart';
''');
    fileStateFor(a).refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_9
        libraryImports
          library_1
          library_4 dart:core synthetic
        fileKinds: library_9
        cycle_5
          dependencies: cycle_1 dart:core
          libraries: library_9
          apiSignature_4
      unlinkedKey: k01
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_4 dart:core synthetic
        fileKinds: library_1
        cycle_1
          dependencies: dart:core
          libraries: library_1
          apiSignature_1
          users: cycle_5
      referencingFiles: file_0
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_4 dart:core synthetic
        fileKinds: library_2
        cycle_2
          dependencies: dart:core
          libraries: library_2
          apiSignature_2
      unlinkedKey: k00
  /home/test/lib/d.dart
    uri: package:test/d.dart
    current
      id: file_3
      kind: library_3
        libraryImports
          library_4 dart:core synthetic
        fileKinds: library_3
        cycle_3
          dependencies: dart:core
          libraries: library_3
          apiSignature_3
      unlinkedKey: k00
libraryCycles
elementFactory
''');

    // Update `b.dart` so that it imports `c.dart` now.
    newFile(b.path, r'''
import 'c.dart';
''');
    fileStateFor(b).refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_9
        libraryImports
          library_10
          library_4 dart:core synthetic
        fileKinds: library_9
        cycle_6
          dependencies: cycle_7 dart:core
          libraries: library_9
          apiSignature_5
      unlinkedKey: k01
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_10
        libraryImports
          library_2
          library_4 dart:core synthetic
        fileKinds: library_10
        cycle_7
          dependencies: cycle_2 dart:core
          libraries: library_10
          apiSignature_6
          users: cycle_6
      referencingFiles: file_0
      unlinkedKey: k02
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_4 dart:core synthetic
        fileKinds: library_2
        cycle_2
          dependencies: dart:core
          libraries: library_2
          apiSignature_2
          users: cycle_7
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/d.dart
    uri: package:test/d.dart
    current
      id: file_3
      kind: library_3
        libraryImports
          library_4 dart:core synthetic
        fileKinds: library_3
        cycle_3
          dependencies: dart:core
          libraries: library_3
          apiSignature_3
      unlinkedKey: k00
libraryCycles
elementFactory
''');

    // Update `b.dart` so that it exports `d.dart` instead.
    newFile(b.path, r'''
export 'd.dart';
''');
    fileStateFor(b).refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_9
        libraryImports
          library_11
          library_4 dart:core synthetic
        fileKinds: library_9
        cycle_8
          dependencies: cycle_9 dart:core
          libraries: library_9
          apiSignature_7
      unlinkedKey: k01
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_11
        libraryImports
          library_4 dart:core synthetic
        libraryExports
          library_3
        fileKinds: library_11
        cycle_9
          dependencies: cycle_3 dart:core
          libraries: library_11
          apiSignature_8
          users: cycle_8
      referencingFiles: file_0
      unlinkedKey: k03
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_4 dart:core synthetic
        fileKinds: library_2
        cycle_2
          dependencies: dart:core
          libraries: library_2
          apiSignature_2
      unlinkedKey: k00
  /home/test/lib/d.dart
    uri: package:test/d.dart
    current
      id: file_3
      kind: library_3
        libraryImports
          library_4 dart:core synthetic
        fileKinds: library_3
        cycle_3
          dependencies: dart:core
          libraries: library_3
          apiSignature_3
          users: cycle_9
      referencingFiles: file_1
      unlinkedKey: k00
libraryCycles
elementFactory
''');

    // Update `a.dart` so that it does not import `b.dart` anymore.
    // Note that `a.dart` has its initial API signature.
    // ...and `b.dart` has no users.
    newFile(a.path, '');
    fileStateFor(a).refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_12
        libraryImports
          library_4 dart:core synthetic
        fileKinds: library_12
        cycle_10
          dependencies: dart:core
          libraries: library_12
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_11
        libraryImports
          library_4 dart:core synthetic
        libraryExports
          library_3
        fileKinds: library_11
        cycle_9
          dependencies: cycle_3 dart:core
          libraries: library_11
          apiSignature_8
      unlinkedKey: k03
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_4 dart:core synthetic
        fileKinds: library_2
        cycle_2
          dependencies: dart:core
          libraries: library_2
          apiSignature_2
      unlinkedKey: k00
  /home/test/lib/d.dart
    uri: package:test/d.dart
    current
      id: file_3
      kind: library_3
        libraryImports
          library_4 dart:core synthetic
        fileKinds: library_3
        cycle_3
          dependencies: dart:core
          libraries: library_3
          apiSignature_3
          users: cycle_9
      referencingFiles: file_1
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_libraryCycle_cycle_export() {
    var a = newFile('$testPackageLibPath/a.dart', r'''
export 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
export 'a.dart';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        libraryExports
          library_1
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0 library_1
          apiSignature_0
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_2 dart:core synthetic
        libraryExports
          library_0
        fileKinds: library_1
        cycle_0
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Update `a.dart` so that it does not export `b.dart` anymore.
    newFile(a.path, '');
    fileStateFor(a).refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_7
        libraryImports
          library_2 dart:core synthetic
        fileKinds: library_7
        cycle_2
          dependencies: dart:core
          libraries: library_7
          apiSignature_1
          users: cycle_3
      referencingFiles: file_1
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_2 dart:core synthetic
        libraryExports
          library_7
        fileKinds: library_1
        cycle_3
          dependencies: cycle_2 dart:core
          libraries: library_1
          apiSignature_2
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_libraryCycle_cycle_import() {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1
          library_2 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0 library_1
          apiSignature_0
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_0
          library_2 dart:core synthetic
        fileKinds: library_1
        cycle_0
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Update a.dart so that it does not import b.dart anymore.
    newFile(a.path, '');
    fileStateFor(a).refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_7
        libraryImports
          library_2 dart:core synthetic
        fileKinds: library_7
        cycle_2
          dependencies: dart:core
          libraries: library_7
          apiSignature_1
          users: cycle_3
      referencingFiles: file_1
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_7
          library_2 dart:core synthetic
        fileKinds: library_1
        cycle_3
          dependencies: cycle_2 dart:core
          libraries: library_1
          apiSignature_2
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  // TODO(scheglov): Implement `asLibrary` testing.
  test_libraryCycle_part() {
//     var a_path = convertPath('/aaa/lib/a.dart');
//     var b_path = convertPath('/aaa/lib/b.dart');
//
//     newFile(a_path, r'''
// part 'b.dart';
// ''');
//     newFile(b_path, r'''
// part of 'a.dart';
// ''');
//
//     var a_file = fileSystemState.getFileForPath(a_path);
//     var b_file = fileSystemState.getFileForPath(b_path);
//     _assertFilesWithoutLibraryCycle([a_file, b_file]);
//
//     // Compute the library cycle for 'a.dart', the library.
//     var a_libraryCycle = a_file.libraryCycle;
//     _assertFilesWithoutLibraryCycle([b_file]);
//
//     // The part 'b.dart' has its own library cycle.
//     // If the user chooses to import a part, it is a compile-time error.
//     // We could handle this in different ways:
//     // 1. Completely ignore an import of a file with a `part of` directive.
//     // 2. Treat such file as a library anyway.
//     // By giving a part its own library cycle we support (2).
//     var b_libraryCycle = b_file.libraryCycle;
//     expect(b_libraryCycle, isNot(same(a_libraryCycle)));
//     _assertFilesWithoutLibraryCycle([]);
  }

  test_newFile_doesNotExist() {
    var a = getFile('$testPackageLibPath/a.dart');

    var file = fileStateFor(a);
    expect(file.path, a.path);
    expect(file.uri, Uri.parse('package:test/a.dart'));
    expect(file.content, '');
    expect(file.exists, isFalse);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_hasLibraryDirective_hasPartOfDirective() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
library L;
part of L;
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: L
        libraryImports
          library_1 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_dartCore() async {
    var core = fsStateFor(testFile).getFileForUri(
      Uri.parse('dart:core'),
    );

    var coreKind = core.file.kind as LibraryFileKind;
    for (var import in coreKind.libraryImports) {
      if (import.isSyntheticDartCore) {
        fail('dart:core should not import itself');
      }
    }
  }

  test_newFile_library_docImports() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
/// @docImport 'dart:async';
/// @docImport 'dart:math';
library;
''');

    fileStateFor(a);

    // Note, no dependencies on `dart:async` or `dart:math`.
    // They don't affect the element model.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        docImports
          library_3 dart:async
          library_5 dart:math
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_exports_dart() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
export 'dart:async';
export 'dart:math';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        libraryExports
          library_3 dart:async
          library_5 dart:math
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_exports_emptyUri() {
    var a = newFile('$testPackageLibPath/a.dart', r'''
export '';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        libraryExports
          library_0
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      referencingFiles: file_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_exports_inSummary_library() async {
    librarySummaryFiles = [
      await buildPackageFooSummary(files: {
        'lib/foo.dart': 'class F {}',
      }),
    ];
    sdkSummaryFile = await writeSdkSummary();

    var a = newFile('$testPackageLibPath/a.dart', r'''
export 'dart:async';
export 'package:foo/foo.dart';
export 'b.dart';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          inSummary dart:core synthetic
        libraryExports
          inSummary dart:async
          inSummary package:foo/foo.dart
          library_1
        fileKinds: library_0
        cycle_0
          dependencies: cycle_1
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          inSummary dart:core synthetic
        fileKinds: library_1
        cycle_1
          dependencies: none
          libraries: library_1
          apiSignature_1
          users: cycle_0
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
  hasReader
    package:foo/foo.dart
''');
  }

  test_newFile_library_exports_inSummary_part() async {
    librarySummaryFiles = [
      await buildPackageFooSummary(files: {
        'lib/foo.dart': "part 'foo2.dart';",
        'lib/foo2.dart': "part of 'foo.dart';",
      }),
    ];
    sdkSummaryFile = await writeSdkSummary();

    var a = newFile('$testPackageLibPath/a.dart', r'''
export 'package:foo/foo2.dart';
export 'b.dart';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          inSummary dart:core synthetic
        libraryExports
          inSummary package:foo/foo2.dart notLibrary
          library_1
        fileKinds: library_0
        cycle_0
          dependencies: cycle_1
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          inSummary dart:core synthetic
        fileKinds: library_1
        cycle_1
          dependencies: none
          libraries: library_1
          apiSignature_1
          users: cycle_0
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
  hasReader
    package:foo/foo.dart
''');
  }

  test_newFile_library_exports_noRelativeUri() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
export ':net';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        libraryExports
          uriStr: :net
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_exports_noRelativeUriStr() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
export '${'foo.dart'}';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        libraryExports
          noUriStr
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_exports_noSource() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
export 'foo:bar';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        libraryExports
          uri: foo:bar
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_exports_package() async {
    var c = newFile('$testPackageLibPath/c.dart', r'''
export 'a.dart';
export 'package:test/b.dart';
''');

    fileStateFor(c);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
          users: cycle_2
      referencingFiles: file_2
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_3 dart:core synthetic
        fileKinds: library_1
        cycle_1
          dependencies: dart:core
          libraries: library_1
          apiSignature_1
          users: cycle_2
      referencingFiles: file_2
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_3 dart:core synthetic
        libraryExports
          library_0
          library_1
        fileKinds: library_2
        cycle_2
          dependencies: cycle_0 cycle_1 dart:core
          libraries: library_2
          apiSignature_2
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_library_exports_part() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of my.lib;
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
export 'a.dart';
''');

    fileStateFor(b);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfName_0
        name: my.lib
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_2 dart:core synthetic
        libraryExports
          notLibrary file_0
        fileKinds: library_1
        cycle_0
          dependencies: dart:core
          libraries: library_1
          apiSignature_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_library_imports_emptyUri() {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import '';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_0
          library_1 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      referencingFiles: file_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_imports_library_dart() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'dart:async';
import 'dart:math';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:async
          library_5 dart:math
          library_1 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_imports_library_dart_explicitDartCore() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'dart:core';
import 'dart:math';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core
          library_5 dart:math
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_imports_library_inSummary_library() async {
    librarySummaryFiles = [
      await buildPackageFooSummary(files: {
        'lib/foo.dart': 'class F {}',
      }),
    ];
    sdkSummaryFile = await writeSdkSummary();

    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'dart:async';
import 'package:foo/foo.dart';
import 'b.dart';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          inSummary dart:async
          inSummary package:foo/foo.dart
          library_1
          inSummary dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: cycle_1
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          inSummary dart:core synthetic
        fileKinds: library_1
        cycle_1
          dependencies: none
          libraries: library_1
          apiSignature_1
          users: cycle_0
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
  hasReader
    package:foo/foo.dart
''');
  }

  test_newFile_library_imports_library_inSummary_part() async {
    librarySummaryFiles = [
      await buildPackageFooSummary(files: {
        'lib/foo.dart': "part 'foo2.dart';",
        'lib/foo2.dart': "part of 'foo.dart';",
      }),
    ];
    sdkSummaryFile = await writeSdkSummary();

    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'package:foo/foo2.dart';
import 'b.dart';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          inSummary package:foo/foo2.dart notLibrary
          library_1
          inSummary dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: cycle_1
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          inSummary dart:core synthetic
        fileKinds: library_1
        cycle_1
          dependencies: none
          libraries: library_1
          apiSignature_1
          users: cycle_0
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
  hasReader
    package:foo/foo.dart
''');
  }

  test_newFile_library_imports_library_package() async {
    newFile('$testPackageLibPath/a.dart', '');
    newFile('$testPackageLibPath/b.dart', '');

    var c = newFile('$testPackageLibPath/c.dart', r'''
import 'a.dart';
import 'package:test/b.dart';
''');

    fileStateFor(c);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
          users: cycle_2
      referencingFiles: file_2
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_3 dart:core synthetic
        fileKinds: library_1
        cycle_1
          dependencies: dart:core
          libraries: library_1
          apiSignature_1
          users: cycle_2
      referencingFiles: file_2
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_0
          library_1
          library_3 dart:core synthetic
        fileKinds: library_2
        cycle_2
          dependencies: cycle_0 cycle_1 dart:core
          libraries: library_2
          apiSignature_2
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_library_imports_library_package_twice() async {
    newFile('$testPackageLibPath/a.dart', '');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';
import 'a.dart';
''');

    fileStateFor(b);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
          users: cycle_1
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_0
          library_0
          library_2 dart:core synthetic
        fileKinds: library_1
        cycle_1
          dependencies: cycle_0 dart:core
          libraries: library_1
          apiSignature_1
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_library_imports_noRelativeUri() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import ':net';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          uriStr: :net
          library_1 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_imports_noRelativeUriStr() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import '${'foo.dart'}';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          noUriStr
          library_1 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_imports_noSource() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
import 'foo:bar';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          uri: foo:bar
          library_1 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_imports_part() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of my.lib;
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';
''');

    fileStateFor(b);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfName_0
        name: my.lib
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          notLibrary file_0
          library_2 dart:core synthetic
        fileKinds: library_1
        cycle_0
          dependencies: dart:core
          libraries: library_1
          apiSignature_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_library_includePart_withoutPartOf() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
// no part of
''');

    var aState = fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          notPart file_1
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_2 dart:core synthetic
        fileKinds: library_1
        cycle_1
          dependencies: dart:core
          libraries: library_1
          apiSignature_1
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Refreshing the library does not change this.
    aState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_7
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          notPart file_1
        fileKinds: library_7
        cycle_3
          dependencies: dart:core
          libraries: library_7
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_2 dart:core synthetic
        fileKinds: library_1
        cycle_1
          dependencies: dart:core
          libraries: library_1
          apiSignature_1
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_library_parts_configurations_useDefault() {
    declaredVariables = {
      'dart.library.io': 'false',
    };

    newFile('$testPackageLibPath/foo.dart', r'''
part of 'test.dart';
class A {}
''');

    newFile('$testPackageLibPath/foo_io.dart', r'''
part of 'test.dart';
class A {}
''');

    newFile('$testPackageLibPath/foo_html.dart', r'''
part of 'test.dart';
class A {}
''');

    newFile(testFile.path, r'''
part 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');

    fileStateFor(testFile);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/foo.dart
    uri: package:test/foo.dart
    current
      id: file_0
      kind: partOfUriKnown_0
        uriFile: file_3
        library: library_3
      referencingFiles: file_3
      unlinkedKey: k00
  /home/test/lib/foo_html.dart
    uri: package:test/foo_html.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_3
      unlinkedKey: k00
  /home/test/lib/foo_io.dart
    uri: package:test/foo_io.dart
    current
      id: file_2
      kind: partOfUriKnown_2
        uriFile: file_3
      unlinkedKey: k00
  /home/test/lib/test.dart
    uri: package:test/test.dart
    current
      id: file_3
      kind: library_3
        libraryImports
          library_4 dart:core synthetic
        partIncludes
          partOfUriKnown_0
        fileKinds: library_3 partOfUriKnown_0
        cycle_0
          dependencies: dart:core
          libraries: library_3
          apiSignature_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_library_parts_configurations_useFirst() {
    declaredVariables = {
      'dart.library.io': 'true',
      'dart.library.html': 'false',
    };

    newFile('$testPackageLibPath/foo.dart', r'''
part of 'test.dart';
class A {}
''');

    newFile('$testPackageLibPath/foo_io.dart', r'''
part of 'test.dart';
class A {}
''');

    newFile('$testPackageLibPath/foo_html.dart', r'''
part of 'test.dart';
class A {}
''');

    newFile(testFile.path, r'''
part 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');

    fileStateFor(testFile);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/foo.dart
    uri: package:test/foo.dart
    current
      id: file_0
      kind: partOfUriKnown_0
        uriFile: file_3
      unlinkedKey: k00
  /home/test/lib/foo_html.dart
    uri: package:test/foo_html.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_3
      unlinkedKey: k00
  /home/test/lib/foo_io.dart
    uri: package:test/foo_io.dart
    current
      id: file_2
      kind: partOfUriKnown_2
        uriFile: file_3
        library: library_3
      referencingFiles: file_3
      unlinkedKey: k00
  /home/test/lib/test.dart
    uri: package:test/test.dart
    current
      id: file_3
      kind: library_3
        libraryImports
          library_4 dart:core synthetic
        partIncludes
          partOfUriKnown_2
        fileKinds: library_3 partOfUriKnown_2
        cycle_0
          dependencies: dart:core
          libraries: library_3
          apiSignature_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_library_parts_configurations_useSecond() {
    declaredVariables = {
      'dart.library.io': 'false',
      'dart.library.html': 'true',
    };

    newFile('$testPackageLibPath/foo.dart', r'''
part of 'test.dart';
class A {}
''');

    newFile('$testPackageLibPath/foo_io.dart', r'''
part of 'test.dart';
class A {}
''');

    newFile('$testPackageLibPath/foo_html.dart', r'''
part of 'test.dart';
class A {}
''');

    newFile(testFile.path, r'''
part 'foo.dart'
  if (dart.library.io) 'foo_io.dart'
  if (dart.library.html) 'foo_html.dart';
''');

    fileStateFor(testFile);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/foo.dart
    uri: package:test/foo.dart
    current
      id: file_0
      kind: partOfUriKnown_0
        uriFile: file_3
      unlinkedKey: k00
  /home/test/lib/foo_html.dart
    uri: package:test/foo_html.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_3
        library: library_3
      referencingFiles: file_3
      unlinkedKey: k00
  /home/test/lib/foo_io.dart
    uri: package:test/foo_io.dart
    current
      id: file_2
      kind: partOfUriKnown_2
        uriFile: file_3
      unlinkedKey: k00
  /home/test/lib/test.dart
    uri: package:test/test.dart
    current
      id: file_3
      kind: library_3
        libraryImports
          library_4 dart:core synthetic
        partIncludes
          partOfUriKnown_1
        fileKinds: library_3 partOfUriKnown_1
        cycle_0
          dependencies: dart:core
          libraries: library_3
          apiSignature_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_library_parts_emptyUri() {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part '';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        partIncludes
          notPart file_0
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      referencingFiles: file_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_parts_invalidUri_cannotParse() {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'da:';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        partIncludes
          uri: da:
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_parts_invalidUri_interpolation() {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part '${'foo.dart'}';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        partIncludes
          noUri
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_parts_invalidUri_noSource() {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'foo:bar';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        partIncludes
          uri: foo:bar
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_parts_ofUri_two() {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'c.dart';
class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'c.dart';
class B {}
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
part 'a.dart';
part 'b.dart';
''');

    fileStateFor(c);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfUriKnown_0
        uriFile: file_2
        library: library_2
      referencingFiles: file_2
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_2
        library: library_2
      referencingFiles: file_2
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_3 dart:core synthetic
        partIncludes
          partOfUriKnown_0
          partOfUriKnown_1
        fileKinds: library_2 partOfUriKnown_0 partOfUriKnown_1
        cycle_0
          dependencies: dart:core
          libraries: library_2
          apiSignature_0
      unlinkedKey: k02
libraryCycles
elementFactory
''');

    // Update `a.dart`, updates the library.
    newFile(a.path, r'''
part of 'c.dart';
class A2 {}
''');
    fileStateFor(a).refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfUriKnown_8
        uriFile: file_2
        library: library_2
      referencingFiles: file_2
      unlinkedKey: k03
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_2
        library: library_2
      referencingFiles: file_2
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_3 dart:core synthetic
        partIncludes
          partOfUriKnown_8
          partOfUriKnown_1
        fileKinds: library_2 partOfUriKnown_8 partOfUriKnown_1
        cycle_2
          dependencies: dart:core
          libraries: library_2
          apiSignature_1
      unlinkedKey: k02
libraryCycles
elementFactory
''');

    // Update `b.dart`, updates the library.
    newFile(b.path, r'''
part of 'c.dart';
class B2 {}
''');
    fileStateFor(b).refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfUriKnown_8
        uriFile: file_2
        library: library_2
      referencingFiles: file_2
      unlinkedKey: k03
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_9
        uriFile: file_2
        library: library_2
      referencingFiles: file_2
      unlinkedKey: k04
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_3 dart:core synthetic
        partIncludes
          partOfUriKnown_8
          partOfUriKnown_9
        fileKinds: library_2 partOfUriKnown_8 partOfUriKnown_9
        cycle_3
          dependencies: dart:core
          libraries: library_2
          apiSignature_2
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_newFile_libraryDirective() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
library my;
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my
        libraryImports
          library_1 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_noDirectives() async {
    var a = newFile('$testPackageLibPath/a.dart', '');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_1 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfName() async {
    var a = newFile('$testPackageLibPath/nested/a.dart', r'''
library my.lib;
part '../b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of my.lib;
''');

    fileStateFor(b);

    // We don't know the library initially.
    // Even though the library file exists, we have not seen it yet.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_0
      kind: partOfName_0
        name: my.lib
      unlinkedKey: k00
libraryCycles
elementFactory
''');

    // Read the library file.
    fileStateFor(a);

    // Now the part knows its library.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_0
      kind: partOfName_0
        libraries: library_1
        library: library_1
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/nested/a.dart
    uri: package:test/nested/a.dart
    current
      id: file_1
      kind: library_1
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfName_0
        fileKinds: library_1 partOfName_0
        cycle_0
          dependencies: dart:core
          libraries: library_1
          apiSignature_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfName_differentName() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
library my.lib;
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of other.lib;
''');

    fileStateFor(b);

    // We don't know the library initially.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          notPart file_1
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfName_1
        name: other.lib
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Read the library file.
    fileStateFor(a);

    // We still don't know the library, because the part wants `other.lib`,
    // but `a.dart` that includes `b.dart` has the name `my.lib`.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          notPart file_1
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfName_1
        name: other.lib
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfName_discoverSiblingLibrary() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
library my.lib;
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of my.lib;
''');

    var bState = fileStateFor(b);

    // The library is discovered by looking at sibling files.
    var bKind = bState.kind as PartOfNameFileKind;
    expect(bKind.library?.file.resource, a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfName_1
        fileKinds: library_0 partOfName_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfName_1
        libraries: library_0
        library: library_0
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfName_twoLibraries() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
library my.lib;
part 'c.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
library my.lib;
part 'c.dart';
''');

    newFile('$testPackageLibPath/c.dart', r'''
part of my.lib;
''');

    var aState = fileStateFor(a);

    // When reading `a.dart` we also read `c.dart` part.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfName_1
        fileKinds: library_0 partOfName_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfName_1
        libraries: library_0
        library: library_0
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // After reading `b.dart` the part has two libraries to choose from.
    // We still keep `a.dart`, because its path is sorted first.
    var bState = fileStateFor(b);
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfName_1
        fileKinds: library_0 partOfName_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_7
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfName_1
        fileKinds: library_7 partOfName_1
        cycle_2
          dependencies: dart:core
          libraries: library_7
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfName_1
        libraries: library_0 library_7
        library: library_0
      referencingFiles: file_0 file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Refresh `b.dart`, the part still uses `a.dart` as the library.
    bState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfName_1
        fileKinds: library_0 partOfName_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_8
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfName_1
        fileKinds: library_8 partOfName_1
        cycle_3
          dependencies: dart:core
          libraries: library_8
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfName_1
        libraries: library_0 library_8
        library: library_0
      referencingFiles: file_0 file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Refresh `a.dart`, the part still uses `a.dart` as the library.
    aState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_9
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfName_1
        fileKinds: library_9 partOfName_1
        cycle_4
          dependencies: dart:core
          libraries: library_9
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_8
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfName_1
        fileKinds: library_8 partOfName_1
        cycle_3
          dependencies: dart:core
          libraries: library_8
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfName_1
        libraries: library_8 library_9
        library: library_9
      referencingFiles: file_0 file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Exclude the part from `a.dart`, switch to `b.dart` instead.
    newFile(a.path, '');
    aState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_10
        libraryImports
          library_2 dart:core synthetic
        fileKinds: library_10
        cycle_5
          dependencies: dart:core
          libraries: library_10
          apiSignature_2
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_8
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfName_1
        fileKinds: library_8 partOfName_1
        cycle_3
          dependencies: dart:core
          libraries: library_8
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfName_1
        libraries: library_8
        library: library_8
      referencingFiles: file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Exclude the part from `b.dart`, no library.
    newFile(b.path, '');
    bState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_10
        libraryImports
          library_2 dart:core synthetic
        fileKinds: library_10
        cycle_5
          dependencies: dart:core
          libraries: library_10
          apiSignature_2
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_11
        libraryImports
          library_2 dart:core synthetic
        fileKinds: library_11
        cycle_6
          dependencies: dart:core
          libraries: library_11
          apiSignature_3
      unlinkedKey: k02
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfName_1
        name: my.lib
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Include into `b.dart`, use it as the library.
    newFile(b.path, r'''
library my.lib;
part 'c.dart';
''');
    bState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_10
        libraryImports
          library_2 dart:core synthetic
        fileKinds: library_10
        cycle_5
          dependencies: dart:core
          libraries: library_10
          apiSignature_2
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_12
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfName_1
        fileKinds: library_12 partOfName_1
        cycle_7
          dependencies: dart:core
          libraries: library_12
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfName_1
        libraries: library_12
        library: library_12
      referencingFiles: file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Include into `a.dart`, switch to `a.dart`.
    newFile(a.path, r'''
library my.lib;
part 'c.dart';
''');
    aState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_13
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfName_1
        fileKinds: library_13 partOfName_1
        cycle_8
          dependencies: dart:core
          libraries: library_13
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_12
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfName_1
        fileKinds: library_12 partOfName_1
        cycle_7
          dependencies: dart:core
          libraries: library_12
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfName_1
        libraries: library_12 library_13
        library: library_13
      referencingFiles: file_0 file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfUri_cycle1_partIncludeSelf() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'b.dart';
part 'b.dart';
''');

    fileStateFor(a);

    // There is a cycle of parts from `b.dart` to itself.
    // This does not lead to a library, so it is absent.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          notPart file_1
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_1
        partIncludes
          partOfUriKnown_1
      referencingFiles: file_0 file_1
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfUri_cycle2() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of a 'a.dart';
part 'c.dart';
''');

    newFile('$testPackageLibPath/c.dart', r'''
part of 'b.dart';
part 'b.dart';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:core synthetic
        partIncludes
          notPart file_1
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfName_1
        name: a
        partIncludes
          partOfUriKnown_2
      referencingFiles: file_0 file_2
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: partOfUriKnown_2
        uriFile: file_1
        partIncludes
          notPart file_1
      referencingFiles: file_1
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfUri_doesNotExist() async {
    var a = getFile('$testPackageLibPath/a.dart');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    var bState = fileStateFor(b);

    // The URI in `part of URI` tells us which library to use.
    // However it does not exist, so it does not include the file, so the
    // part file will not be analyzed during the library analysis.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Create `a.dart` that includes the part file.
    newFile(a.path, r'''
part 'b.dart';
''');

    // The library file has already been read because of `part of uri`.
    // So, we explicitly refresh it.
    var aState = fileStateFor(a);
    aState.refresh();

    // Now the part file knows its library.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_7
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfUriKnown_1
        fileKinds: library_7 partOfUriKnown_1
        cycle_2
          dependencies: dart:core
          libraries: library_7
          apiSignature_1
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
        library: library_7
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Refreshing the part file does not break the kind.
    bState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_7
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfUriKnown_8
        fileKinds: library_7 partOfUriKnown_8
        cycle_3
          dependencies: dart:core
          libraries: library_7
          apiSignature_1
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_8
        uriFile: file_0
        library: library_7
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfUri_duplicate() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'c.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part 'c.dart';
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
part of 'a.dart';
part of 'b.dart';
''');

    fileStateFor(a);
    fileStateFor(b);
    fileStateFor(c);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:core synthetic
        partIncludes
          partOfUriKnown_2
        fileKinds: library_0 partOfUriKnown_2
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_3 dart:core synthetic
        partIncludes
          notPart file_2
        fileKinds: library_1
        cycle_1
          dependencies: dart:core
          libraries: library_1
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: partOfUriKnown_2
        uriFile: file_0
        library: library_0
      referencingFiles: file_0 file_1
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfUri_noRelativeUri() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of ':net';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfUriUnknown_0
        uri: :net
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfUri_noRelativeUriStr() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of '${'foo.dart'}';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfUriUnknown_0
        uri: null
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfUri_noSource() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'foo:bar';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfUriUnknown_0
        uri: foo:bar
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfUri_targetLibrary_hasPartInclude() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    fileStateFor(b);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfUriKnown_1
        fileKinds: library_0 partOfUriKnown_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
        library: library_0
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfUri_targetLibrary_noPartInclude() async {
    var a = newFile('$testPackageLibPath/a.dart', '');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    fileStateFor(b);

    // We can find `a.dart` using the URI.
    // But it does not include `b.dart`, so we find the file that corresponds
    // to the URI, but refuse to consider it a part.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Refreshing `a.dart` does not change anything.
    fileStateFor(a).refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_7
        libraryImports
          library_2 dart:core synthetic
        fileKinds: library_7
        cycle_2
          dependencies: dart:core
          libraries: library_7
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfUri_targetNotExists() async {
    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    fileStateFor(b);

    // We can find `a.dart` from `b.dart` using the URI.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfUri_targetPart_hasPartInclude() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
part 'c.dart';
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
part of 'b.dart';
''');

    fileStateFor(c);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:core synthetic
        partIncludes
          partOfUriKnown_1
        fileKinds: library_0 partOfUriKnown_1 partOfUriKnown_2
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
        library: library_0
        partIncludes
          partOfUriKnown_2
      referencingFiles: file_0
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: partOfUriKnown_2
        uriFile: file_1
        library: library_0
      referencingFiles: file_1
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfUri_targetPart_hasPartInclude_disconnected() async {
    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
part 'c.dart';
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
part of 'b.dart';
''');

    fileStateFor(c);

    // `b.dart` points at `a.dart`, but `a.dart` does not include it.
    // So, we can resolve the file, but decline to consider it a part.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
        partIncludes
          partOfUriKnown_2
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: partOfUriKnown_2
        uriFile: file_1
      referencingFiles: file_1
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfUri_targetPart_noPartInclude() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
part of 'b.dart';
''');

    fileStateFor(c);

    // `c.dart` points at `b.dart`, but `b.dart` does not include it.
    // So, we can resolve the file, but decline to consider it a part.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:core synthetic
        partIncludes
          partOfUriKnown_1
        fileKinds: library_0 partOfUriKnown_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
        library: library_0
      referencingFiles: file_0
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: partOfUriKnown_2
        uriFile: file_1
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfUri_twoLibraries() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'c.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part 'c.dart';
''');

    newFile('$testPackageLibPath/c.dart', r'''
part of 'a.dart';
''');

    var aState = fileStateFor(a);

    // We set the library while reading `a.dart` file.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfUriKnown_1
        fileKinds: library_0 partOfUriKnown_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
        library: library_0
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Reading `b.dart` does not update the part.
    var bState = fileStateFor(b);
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfUriKnown_1
        fileKinds: library_0 partOfUriKnown_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_7
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          notPart file_1
        fileKinds: library_7
        cycle_2
          dependencies: dart:core
          libraries: library_7
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
        library: library_0
      referencingFiles: file_0 file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Refreshing `b.dart` does not update the part.
    bState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfUriKnown_1
        fileKinds: library_0 partOfUriKnown_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_8
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          notPart file_1
        fileKinds: library_8
        cycle_3
          dependencies: dart:core
          libraries: library_8
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
        library: library_0
      referencingFiles: file_0 file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Refreshing `a.dart` does not update the part.
    aState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_9
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfUriKnown_1
        fileKinds: library_9 partOfUriKnown_1
        cycle_4
          dependencies: dart:core
          libraries: library_9
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_8
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          notPart file_1
        fileKinds: library_8
        cycle_3
          dependencies: dart:core
          libraries: library_8
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
        library: library_9
      referencingFiles: file_0 file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Exclude the part from `a.dart`, the URI in `part of` still resolves
    // to `a.dart`, but it is not the library of the part anymore.
    newFile(a.path, '');
    aState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_10
        libraryImports
          library_2 dart:core synthetic
        fileKinds: library_10
        cycle_5
          dependencies: dart:core
          libraries: library_10
          apiSignature_2
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_8
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          notPart file_1
        fileKinds: library_8
        cycle_3
          dependencies: dart:core
          libraries: library_8
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
      referencingFiles: file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Exclude the part from `b.dart`, no changes.
    newFile(b.path, '');
    bState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_10
        libraryImports
          library_2 dart:core synthetic
        fileKinds: library_10
        cycle_5
          dependencies: dart:core
          libraries: library_10
          apiSignature_2
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_11
        libraryImports
          library_2 dart:core synthetic
        fileKinds: library_11
        cycle_6
          dependencies: dart:core
          libraries: library_11
          apiSignature_3
      unlinkedKey: k02
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Include into `b.dart`, no changes.
    newFile(b.path, r'''
part 'c.dart';
''');
    bState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_10
        libraryImports
          library_2 dart:core synthetic
        fileKinds: library_10
        cycle_5
          dependencies: dart:core
          libraries: library_10
          apiSignature_2
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_12
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          notPart file_1
        fileKinds: library_12
        cycle_7
          dependencies: dart:core
          libraries: library_12
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
      referencingFiles: file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Include into `a.dart`, restore `a.dart` as the library of the part.
    newFile(a.path, r'''
part 'c.dart';
''');
    aState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_13
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfUriKnown_1
        fileKinds: library_13 partOfUriKnown_1
        cycle_8
          dependencies: dart:core
          libraries: library_13
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_7
      kind: library_12
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          notPart file_1
        fileKinds: library_12
        cycle_7
          dependencies: dart:core
          libraries: library_12
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
        library: library_13
      referencingFiles: file_0 file_7
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_part_docImports() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
/// @docImport 'dart:async';
/// @docImport 'dart:math';
part of 'a.dart';
''');

    fileStateFor(b);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfUriKnown_1
        fileKinds: library_0 partOfUriKnown_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
        library: library_0
        docImports
          library_4 dart:async
          library_6 dart:math
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Remove 'dart:math'.
    modifyFile2(b, r'''
/// @docImport 'dart:async';
part of 'a.dart';
''');
    fileStateFor(b).refresh();

    // The API signature of the cycle is the same.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfUriKnown_7
        fileKinds: library_0 partOfUriKnown_7
        cycle_2
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_7
        uriFile: file_0
        library: library_0
        docImports
          library_4 dart:async
      referencingFiles: file_0
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_part_libraryExports() async {
    newFile('$testPackageLibPath/a.dart', r'''
export 'dart:collection';
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
export 'dart:async';
''');

    fileStateFor(b);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        libraryExports
          library_6 dart:collection
        partIncludes
          partOfUriKnown_1
        fileKinds: library_0 partOfUriKnown_1
        cycle_0
          dependencies: dart:collection dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
        library: library_0
        libraryExports
          library_4 dart:async
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Add export 'dart:math'.
    modifyFile2(b, r'''
part of 'a.dart';
export 'dart:async';
export 'dart:math';
''');
    fileStateFor(b).refresh();

    // New library cycle, with new 'apiSignature'.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        libraryExports
          library_6 dart:collection
        partIncludes
          partOfUriKnown_8
        fileKinds: library_0 partOfUriKnown_8
        cycle_3
          dependencies: dart:collection dart:core
          libraries: library_0
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_8
        uriFile: file_0
        library: library_0
        libraryExports
          library_4 dart:async
          library_7 dart:math
      referencingFiles: file_0
      unlinkedKey: k02
libraryCycles
elementFactory
''');

    // Remove import 'dart:math'.
    modifyFile2(b, r'''
part of 'a.dart';
export 'dart:async';
''');
    fileStateFor(b).refresh();

    // New library cycle, with the initial 'apiSignature'.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        libraryExports
          library_6 dart:collection
        partIncludes
          partOfUriKnown_9
        fileKinds: library_0 partOfUriKnown_9
        cycle_4
          dependencies: dart:collection dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_9
        uriFile: file_0
        library: library_0
        libraryExports
          library_4 dart:async
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_part_libraryExports_nestedPart() async {
    newFile('$testPackageLibPath/a.dart', r'''
export 'dart:collection';
part 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
part 'c.dart';
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
part of 'b.dart';
export 'dart:async';
''');

    fileStateFor(c);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:core synthetic
        libraryExports
          library_7 dart:collection
        partIncludes
          partOfUriKnown_1
        fileKinds: library_0 partOfUriKnown_1 partOfUriKnown_2
        cycle_0
          dependencies: dart:collection dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
        library: library_0
        partIncludes
          partOfUriKnown_2
      referencingFiles: file_0
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: partOfUriKnown_2
        uriFile: file_1
        library: library_0
        libraryExports
          library_5 dart:async
      referencingFiles: file_1
      unlinkedKey: k02
libraryCycles
elementFactory
''');

    // Add import 'dart:math'.
    modifyFile2(c, r'''
part of 'b.dart';
export 'dart:async';
export 'dart:math';
''');
    fileStateFor(c).refresh();

    // New library cycle, with new 'apiSignature'.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:core synthetic
        libraryExports
          library_7 dart:collection
        partIncludes
          partOfUriKnown_1
        fileKinds: library_0 partOfUriKnown_1 partOfUriKnown_9
        cycle_3
          dependencies: dart:collection dart:core
          libraries: library_0
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
        library: library_0
        partIncludes
          partOfUriKnown_9
      referencingFiles: file_0
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: partOfUriKnown_9
        uriFile: file_1
        library: library_0
        libraryExports
          library_5 dart:async
          library_8 dart:math
      referencingFiles: file_1
      unlinkedKey: k03
libraryCycles
elementFactory
''');

    // Remove import 'dart:math'.
    modifyFile2(c, r'''
part of 'b.dart';
export 'dart:async';
''');
    fileStateFor(c).refresh();

    // New library cycle, with the initial 'apiSignature'.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:core synthetic
        libraryExports
          library_7 dart:collection
        partIncludes
          partOfUriKnown_1
        fileKinds: library_0 partOfUriKnown_1 partOfUriKnown_10
        cycle_4
          dependencies: dart:collection dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
        library: library_0
        partIncludes
          partOfUriKnown_10
      referencingFiles: file_0
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: partOfUriKnown_10
        uriFile: file_1
        library: library_0
        libraryExports
          library_5 dart:async
      referencingFiles: file_1
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_part_libraryImports() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'dart:collection';
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
import 'dart:async';
''');

    fileStateFor(b);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_6 dart:collection
          library_2 dart:core synthetic
        partIncludes
          partOfUriKnown_1
        fileKinds: library_0 partOfUriKnown_1
        cycle_0
          dependencies: dart:collection dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
        library: library_0
        libraryImports
          library_4 dart:async
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Add import 'dart:math'.
    modifyFile2(b, r'''
part of 'a.dart';
import 'dart:async';
import 'dart:math';
''');
    fileStateFor(b).refresh();

    // New library cycle, with new 'apiSignature'.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_6 dart:collection
          library_2 dart:core synthetic
        partIncludes
          partOfUriKnown_8
        fileKinds: library_0 partOfUriKnown_8
        cycle_3
          dependencies: dart:collection dart:core
          libraries: library_0
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_8
        uriFile: file_0
        library: library_0
        libraryImports
          library_4 dart:async
          library_7 dart:math
      referencingFiles: file_0
      unlinkedKey: k02
libraryCycles
elementFactory
''');

    // Remove import 'dart:math'.
    modifyFile2(b, r'''
part of 'a.dart';
import 'dart:async';
''');
    fileStateFor(b).refresh();

    // New library cycle, with the initial 'apiSignature'.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_6 dart:collection
          library_2 dart:core synthetic
        partIncludes
          partOfUriKnown_9
        fileKinds: library_0 partOfUriKnown_9
        cycle_4
          dependencies: dart:collection dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_9
        uriFile: file_0
        library: library_0
        libraryImports
          library_4 dart:async
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_part_libraryImports_nestedPart() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'dart:collection';
part 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
part 'c.dart';
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
part of 'b.dart';
import 'dart:async';
''');

    fileStateFor(c);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_7 dart:collection
          library_3 dart:core synthetic
        partIncludes
          partOfUriKnown_1
        fileKinds: library_0 partOfUriKnown_1 partOfUriKnown_2
        cycle_0
          dependencies: dart:collection dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
        library: library_0
        partIncludes
          partOfUriKnown_2
      referencingFiles: file_0
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: partOfUriKnown_2
        uriFile: file_1
        library: library_0
        libraryImports
          library_5 dart:async
      referencingFiles: file_1
      unlinkedKey: k02
libraryCycles
elementFactory
''');

    // Add import 'dart:math'.
    modifyFile2(c, r'''
part of 'b.dart';
import 'dart:async';
import 'dart:math';
''');
    fileStateFor(c).refresh();

    // New library cycle, with new 'apiSignature'.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_7 dart:collection
          library_3 dart:core synthetic
        partIncludes
          partOfUriKnown_1
        fileKinds: library_0 partOfUriKnown_1 partOfUriKnown_9
        cycle_3
          dependencies: dart:collection dart:core
          libraries: library_0
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
        library: library_0
        partIncludes
          partOfUriKnown_9
      referencingFiles: file_0
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: partOfUriKnown_9
        uriFile: file_1
        library: library_0
        libraryImports
          library_5 dart:async
          library_8 dart:math
      referencingFiles: file_1
      unlinkedKey: k03
libraryCycles
elementFactory
''');

    // Remove import 'dart:math'.
    modifyFile2(c, r'''
part of 'b.dart';
import 'dart:async';
''');
    fileStateFor(c).refresh();

    // New library cycle, with the initial 'apiSignature'.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_7 dart:collection
          library_3 dart:core synthetic
        partIncludes
          partOfUriKnown_1
        fileKinds: library_0 partOfUriKnown_1 partOfUriKnown_10
        cycle_4
          dependencies: dart:collection dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
        library: library_0
        partIncludes
          partOfUriKnown_10
      referencingFiles: file_0
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: partOfUriKnown_10
        uriFile: file_1
        library: library_0
        libraryImports
          library_5 dart:async
      referencingFiles: file_1
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_part_parts() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
part 'c.dart';
''');

    newFile('$testPackageLibPath/c.dart', r'''
part of 'b.dart';
import 'dart:io';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:core synthetic
        partIncludes
          partOfUriKnown_1
        fileKinds: library_0 partOfUriKnown_1 partOfUriKnown_2
        cycle_0
          dependencies: dart:core dart:io
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
        library: library_0
        partIncludes
          partOfUriKnown_2
      referencingFiles: file_0
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: partOfUriKnown_2
        uriFile: file_1
        library: library_0
        libraryImports
          library_8 dart:io
      referencingFiles: file_1
      unlinkedKey: k02
libraryCycles
elementFactory
''');

    // Add new 'd.dart' as a part of 'b.dart'.
    newFile('$testPackageLibPath/d.dart', r'''
part of 'b.dart';
''');

    modifyFile2(b, r'''
part of 'a.dart';
part 'c.dart';
part 'd.dart';
''');
    fileStateFor(b).refresh();

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:core synthetic
        partIncludes
          partOfUriKnown_10
        fileKinds: library_0 partOfUriKnown_10 partOfUriKnown_2 partOfUriKnown_11
        cycle_4
          dependencies: dart:core dart:io
          libraries: library_0
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_10
        uriFile: file_0
        library: library_0
        partIncludes
          partOfUriKnown_2
          partOfUriKnown_11
      referencingFiles: file_0
      unlinkedKey: k03
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: partOfUriKnown_2
        uriFile: file_1
        library: library_0
        libraryImports
          library_8 dart:io
      referencingFiles: file_1
      unlinkedKey: k02
  /home/test/lib/d.dart
    uri: package:test/d.dart
    current
      id: file_10
      kind: partOfUriKnown_11
        uriFile: file_1
        library: library_0
      referencingFiles: file_1
      unlinkedKey: k04
libraryCycles
elementFactory
''');

    // Remove 'c.dart' as a part of 'b.dart'.
    modifyFile2(b, r'''
part of 'a.dart';
part 'd.dart';
''');
    fileStateFor(b).refresh();

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:core synthetic
        partIncludes
          partOfUriKnown_12
        fileKinds: library_0 partOfUriKnown_12 partOfUriKnown_11
        cycle_5
          dependencies: dart:core
          libraries: library_0
          apiSignature_2
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_12
        uriFile: file_0
        library: library_0
        partIncludes
          partOfUriKnown_11
      referencingFiles: file_0
      unlinkedKey: k05
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: partOfUriKnown_2
        uriFile: file_1
        libraryImports
          library_8 dart:io
      unlinkedKey: k02
  /home/test/lib/d.dart
    uri: package:test/d.dart
    current
      id: file_10
      kind: partOfUriKnown_11
        uriFile: file_1
        library: library_0
      referencingFiles: file_1
      unlinkedKey: k04
libraryCycles
elementFactory
''');
  }

  test_refresh_library_importedBy_part() {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
import 'c.dart';
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
class C {}
''');

    fileStateFor(a);

    // `c.dart` is imported by `b.dart`, so it is a dependency of `c.dart`.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:core synthetic
        partIncludes
          partOfUriKnown_1
        fileKinds: library_0 partOfUriKnown_1
        cycle_0
          dependencies: cycle_1 dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
        library: library_0
        libraryImports
          library_2
      referencingFiles: file_0
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_3 dart:core synthetic
        fileKinds: library_2
        cycle_1
          dependencies: dart:core
          libraries: library_2
          apiSignature_1
          users: cycle_0
      referencingFiles: file_1
      unlinkedKey: k02
libraryCycles
elementFactory
''');

    newFile(c.path, r'''
class C2 {}
''');
    fileStateFor(c).refresh();

    // Updated `c.dart` invalidates the library cycle for `a.dart`, both
    // have now different signatures.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:core synthetic
        partIncludes
          partOfUriKnown_1
        fileKinds: library_0 partOfUriKnown_1
        cycle_3
          dependencies: cycle_4 dart:core
          libraries: library_0
          apiSignature_2
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
        library: library_0
        libraryImports
          library_8
      referencingFiles: file_0
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_8
        libraryImports
          library_3 dart:core synthetic
        fileKinds: library_8
        cycle_4
          dependencies: dart:core
          libraries: library_8
          apiSignature_3
          users: cycle_3
      referencingFiles: file_1
      unlinkedKey: k03
libraryCycles
elementFactory
''');
  }

  test_refresh_library_removePart_partOfName() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of my;
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of my;
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
library my;
part 'a.dart';
part 'b.dart';
''');

    var cState = fileStateFor(c);

    // Both part files know the library.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfName_0
        libraries: library_2
        library: library_2
      referencingFiles: file_2
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfName_1
        libraries: library_2
        library: library_2
      referencingFiles: file_2
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        name: my
        libraryImports
          library_3 dart:core synthetic
        partIncludes
          partOfName_0
          partOfName_1
        fileKinds: library_2 partOfName_0 partOfName_1
        cycle_0
          dependencies: dart:core
          libraries: library_2
          apiSignature_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    newFile(c.path, r'''
library my;
part 'b.dart';
''');

    // Stop referencing `a.dart` part file.
    cState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfName_0
        libraries: library_8
        name: my
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfName_1
        libraries: library_8
        library: library_8
      referencingFiles: file_2
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_8
        name: my
        libraryImports
          library_3 dart:core synthetic
        partIncludes
          partOfName_1
        fileKinds: library_8 partOfName_1
        cycle_2
          dependencies: dart:core
          libraries: library_8
          apiSignature_1
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_refresh_library_removePart_partOfUri() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'c.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'c.dart';
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
part 'a.dart';
part 'b.dart';
''');

    var cState = fileStateFor(c);

    // Both part files know the library.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfUriKnown_0
        uriFile: file_2
        library: library_2
      referencingFiles: file_2
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_2
        library: library_2
      referencingFiles: file_2
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_3 dart:core synthetic
        partIncludes
          partOfUriKnown_0
          partOfUriKnown_1
        fileKinds: library_2 partOfUriKnown_0 partOfUriKnown_1
        cycle_0
          dependencies: dart:core
          libraries: library_2
          apiSignature_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    newFile(c.path, r'''
library my;
part 'b.dart';
''');

    // Stop referencing `a.dart` part file.
    cState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfUriKnown_0
        uriFile: file_2
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_2
        library: library_8
      referencingFiles: file_2
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_8
        name: my
        libraryImports
          library_3 dart:core synthetic
        partIncludes
          partOfUriKnown_1
        fileKinds: library_8 partOfUriKnown_1
        cycle_2
          dependencies: dart:core
          libraries: library_8
          apiSignature_1
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_refresh_library_to_partOfName() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
library my.lib;
part 'b.dart';
''');

    // No `part of`, so it is a library.
    var b = newFile('$testPackageLibPath/b.dart', '');

    fileStateFor(a);
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          notPart file_1
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_2 dart:core synthetic
        fileKinds: library_1
        cycle_1
          dependencies: dart:core
          libraries: library_1
          apiSignature_1
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Make it a part.
    newFile(b.path, r'''
part of my.lib;
''');
    fileStateFor(b).refresh();

    // The API signature of `a.dart` is different.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfName_7
        fileKinds: library_0 partOfName_7
        cycle_3
          dependencies: dart:core
          libraries: library_0
          apiSignature_2
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfName_7
        libraries: library_0
        library: library_0
      referencingFiles: file_0
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_refresh_library_to_partOfName_noLibrary() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
library my;
''');

    var aState = fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my
        libraryImports
          library_1 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
libraryCycles
elementFactory
''');

    newFile(a.path, r'''
part of my;
''');

    aState.refresh();

    // No library that includes it, so it stays unknown.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfName_6
        name: my
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_refresh_library_to_partOfUri() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
library b;
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          notPart file_1
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        name: b
        libraryImports
          library_2 dart:core synthetic
        fileKinds: library_1
        cycle_1
          dependencies: dart:core
          libraries: library_1
          apiSignature_1
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Make it a part.
    newFile(b.path, r'''
part of 'a.dart';
''');
    fileStateFor(b).refresh();

    // The API signature is different now.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfUriKnown_7
        fileKinds: library_0 partOfUriKnown_7
        cycle_3
          dependencies: dart:core
          libraries: library_0
          apiSignature_2
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_7
        uriFile: file_0
        library: library_0
      referencingFiles: file_0
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_refresh_partOfName_twoLibraries() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of my.lib;
class A1 {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
library my.lib;
part 'a.dart';
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
library my.lib;
part 'a.dart';
''');

    fileStateFor(b);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfName_0
        libraries: library_1
        library: library_1
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfName_0
        fileKinds: library_1 partOfName_0
        cycle_0
          dependencies: dart:core
          libraries: library_1
          apiSignature_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Get `c.dart`, now there are two libraries to chose from.
    fileStateFor(c);
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfName_0
        libraries: library_1 library_7
        library: library_1
      referencingFiles: file_1 file_7
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfName_0
        fileKinds: library_1 partOfName_0
        cycle_0
          dependencies: dart:core
          libraries: library_1
          apiSignature_0
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_7
      kind: library_7
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfName_0
        fileKinds: library_7 partOfName_0
        cycle_2
          dependencies: dart:core
          libraries: library_7
          apiSignature_1
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Update `a.dart` part.
    newFile(a.path, r'''
part of my.lib;
class A2 {}
''');
    fileStateFor(a).refresh();

    // `a.dart` is still a part.
    // ...but the unlinked signature of `a.dart` is different.
    // API signatures of both `b.dart` and `c.dart` changed.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfName_8
        libraries: library_1 library_7
        library: library_1
      referencingFiles: file_1 file_7
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfName_8
        fileKinds: library_1 partOfName_8
        cycle_3
          dependencies: dart:core
          libraries: library_1
          apiSignature_2
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_7
      kind: library_7
        name: my.lib
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfName_8
        fileKinds: library_7 partOfName_8
        cycle_4
          dependencies: dart:core
          libraries: library_7
          apiSignature_3
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_refresh_partOfUri_nestedPart() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
part 'c.dart';
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
part of 'b.dart';
class C {}
''');

    fileStateFor(a);
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:core synthetic
        partIncludes
          partOfUriKnown_1
        fileKinds: library_0 partOfUriKnown_1 partOfUriKnown_2
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
        library: library_0
        partIncludes
          partOfUriKnown_2
      referencingFiles: file_0
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: partOfUriKnown_2
        uriFile: file_1
        library: library_0
      referencingFiles: file_1
      unlinkedKey: k02
libraryCycles
elementFactory
''');

    modifyFile2(c, r'''
part of 'b.dart';
class C2 {}
''');
    fileStateFor(c).refresh();

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_3 dart:core synthetic
        partIncludes
          partOfUriKnown_1
        fileKinds: library_0 partOfUriKnown_1 partOfUriKnown_8
        cycle_2
          dependencies: dart:core
          libraries: library_0
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
        library: library_0
        partIncludes
          partOfUriKnown_8
      referencingFiles: file_0
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: partOfUriKnown_8
        uriFile: file_1
        library: library_0
      referencingFiles: file_1
      unlinkedKey: k03
libraryCycles
elementFactory
''');
  }

  test_refresh_partOfUri_to_library() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    fileStateFor(a);

    // There is `part of` in `b.dart`, so it is a part.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfUriKnown_1
        fileKinds: library_0 partOfUriKnown_1
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_1
        uriFile: file_0
        library: library_0
      referencingFiles: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    newFile(b.path, r'''
// no part of
''');
    fileStateFor(b).refresh();

    // There are no directives in `b.dart`, so it is a library.
    // Library `a.dart` still considers `b.dart` its part.
    // The API signature of the library cycle for `a.dart` is different now.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          notPart file_1
        fileKinds: library_0
        cycle_2
          dependencies: dart:core
          libraries: library_0
          apiSignature_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_7
        libraryImports
          library_2 dart:core synthetic
        fileKinds: library_7
        cycle_3
          dependencies: dart:core
          libraries: library_7
          apiSignature_2
      referencingFiles: file_0
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_refresh_partOfUri_twoLibraries() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'b.dart';
class A1 {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part 'a.dart';
''');

    var c = newFile('$testPackageLibPath/c.dart', r'''
part 'a.dart';
''');

    fileStateFor(b);
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfUriKnown_0
        uriFile: file_1
        library: library_1
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfUriKnown_0
        fileKinds: library_1 partOfUriKnown_0
        cycle_0
          dependencies: dart:core
          libraries: library_1
          apiSignature_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    fileStateFor(c);
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfUriKnown_0
        uriFile: file_1
        library: library_1
      referencingFiles: file_1 file_7
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfUriKnown_0
        fileKinds: library_1 partOfUriKnown_0
        cycle_0
          dependencies: dart:core
          libraries: library_1
          apiSignature_0
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_7
      kind: library_7
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          notPart file_0
        fileKinds: library_7
        cycle_2
          dependencies: dart:core
          libraries: library_7
          apiSignature_1
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Update `a.dart` part.
    newFile(a.path, r'''
part of 'b.dart';
class A2 {}
''');
    fileStateFor(a).refresh();

    // `a.dart` is still a part.
    // ...but the unlinked signature of `a.dart` is different.
    // The API signatures of `b.dart` is changed, because `a.dart` is its part.
    // But `c.dart` still has the previous API signature.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfUriKnown_8
        uriFile: file_1
        library: library_1
      referencingFiles: file_1 file_7
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          partOfUriKnown_8
        fileKinds: library_1 partOfUriKnown_8
        cycle_3
          dependencies: dart:core
          libraries: library_1
          apiSignature_2
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_7
      kind: library_7
        libraryImports
          library_2 dart:core synthetic
        partIncludes
          notPart file_0
        fileKinds: library_7
        cycle_4
          dependencies: dart:core
          libraries: library_7
          apiSignature_1
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }
}

@reflectiveTest
class FileSystemStateTest with ResourceProviderMixin {
  final ByteStore byteStore = MemoryByteStore();
  final FileContentOverlay contentOverlay = FileContentOverlay();

  final StringBuffer logBuffer = StringBuffer();
  final _GeneratedUriResolverMock generatedUriResolver =
      _GeneratedUriResolverMock();
  late final SourceFactory sourceFactory;
  late final PerformanceLog logger;

  late final FileSystemState fileSystemState;

  void setUp() {
    logger = PerformanceLog(logBuffer);

    var sdkRoot = newFolder('/sdk');
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );
    var sdk = FolderBasedDartSdk(resourceProvider, sdkRoot);

    var packageMap = <String, List<Folder>>{
      'aaa': [getFolder('/aaa/lib')],
      'bbb': [getFolder('/bbb/lib')],
    };

    var packages = Packages({
      'aaa': Package(
        name: 'aaa',
        rootFolder: newFolder('/packages/aaa'),
        libFolder: newFolder('/packages/aaa/lib'),
        languageVersion: null,
      ),
      'bbb': Package(
        name: 'bbb',
        rootFolder: newFolder('/packages/bbb'),
        libFolder: newFolder('/packages/bbb/lib'),
        languageVersion: null,
      ),
    });

    var workspace = BasicWorkspace.find(
      resourceProvider,
      packages,
      convertPath('/test'),
    );

    sourceFactory = SourceFactory([
      DartUriResolver(sdk),
      generatedUriResolver,
      PackageMapUriResolver(resourceProvider, packageMap),
      ResourceUriResolver(resourceProvider)
    ]);

    var analysisOptions = AnalysisOptionsImpl()
      ..contextFeatures = FeatureSet.latestLanguageVersion()
      ..nonPackageFeatureSet = FeatureSet.latestLanguageVersion();
    var featureSetProvider = FeatureSetProvider.build(
      sourceFactory: sourceFactory,
      resourceProvider: resourceProvider,
      packages: Packages.empty,
    );
    fileSystemState = FileSystemState(
      byteStore,
      resourceProvider,
      'contextName',
      sourceFactory,
      workspace,
      DeclaredVariables(),
      Uint32List(0),
      Uint32List(0),
      featureSetProvider,
      AnalysisOptionsMap.forSharedOptions(analysisOptions),
      fileContentStrategy: StoredFileContentStrategy(
        FileContentCache.ephemeral(resourceProvider),
      ),
      prefetchFiles: null,
      isGenerated: (_) => false,
      onNewFile: (file) {},
      testData: null,
      unlinkedUnitStore: UnlinkedUnitStoreImpl(),
    );
  }

  test_definedClassMemberNames() {
    String path = convertPath('/aaa/lib/a.dart');
    newFile(path, r'''
class A {
  int a, b;
  A();
  A.c();
  d() {}
  get e => null;
  set f(_) {}
}
class B {
  g() {}
}
''');
    FileState file = fileSystemState.getFileForPath(path);
    expect(file.definedClassMemberNames,
        unorderedEquals(['a', 'b', 'd', 'e', 'f', 'g']));
  }

  test_definedClassMemberNames_enum() {
    String path = convertPath('/aaa/lib/a.dart');
    newFile(path, r'''
enum E1 {
  v1;
  int field1, field2;
  const E1();
  const E1.namedConstructor();
  void method() {}
  get getter => 0;
  set setter(_) {}
}

enum E2 {
  v2;
  get getter2 => 0;
}
''');
    FileState file = fileSystemState.getFileForPath(path);
    expect(
      file.definedClassMemberNames,
      unorderedEquals([
        'v1',
        'field1',
        'field2',
        'method',
        'getter',
        'setter',
        'v2',
        'getter2',
      ]),
    );
  }

  test_definedTopLevelNames() {
    String path = convertPath('/aaa/lib/a.dart');
    newFile(path, r'''
class A {}
class B = Object with A;
typedef C();
D() {}
get E => null;
set F(_) {}
var G, H;
''');
    FileState file = fileSystemState.getFileForPath(path);
    expect(file.definedTopLevelNames,
        unorderedEquals(['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']));
  }

  test_getFileForPath_samePath() {
    String path = convertPath('/aaa/lib/a.dart');
    FileState file1 = fileSystemState.getFileForPath(path);
    FileState file2 = fileSystemState.getFileForPath(path);
    expect(file2, same(file1));
  }

  test_getFileForUri_invalidUri() {
    var uri = Uri.parse('package:x');
    var resolution = fileSystemState.getFileForUri(uri);
    expect(resolution, isNull);
  }

  test_getFilesSubtypingName_class() {
    String a = convertPath('/a.dart');
    String b = convertPath('/b.dart');

    newFile(a, r'''
class A {}
class B extends A {}
''');
    newFile(b, r'''
class A {}
class D implements A {}
''');

    FileState aFile = fileSystemState.getFileForPath(a);
    FileState bFile = fileSystemState.getFileForPath(b);

    expect(
      fileSystemState.getFilesSubtypingName('A'),
      unorderedEquals([aFile, bFile]),
    );

    // Change b.dart so that it does not subtype A.
    newFile(b, r'''
class C {}
class D implements C {}
''');
    bFile.refresh();
    expect(
      fileSystemState.getFilesSubtypingName('A'),
      unorderedEquals([aFile]),
    );
    expect(
      fileSystemState.getFilesSubtypingName('C'),
      unorderedEquals([bFile]),
    );
  }

  test_getFilesSubtypingName_enum_implements() {
    String a = convertPath('/a.dart');
    String b = convertPath('/b.dart');

    newFile(a, r'''
class A {}
enum E1 implements A {
  v
}
''');
    newFile(b, r'''
class A {}
enum E2 implements A {
  v
}
''');

    FileState aFile = fileSystemState.getFileForPath(a);
    FileState bFile = fileSystemState.getFileForPath(b);

    expect(
      fileSystemState.getFilesSubtypingName('A'),
      unorderedEquals([aFile, bFile]),
    );

    // Change b.dart so that it does not subtype A.
    newFile(b, r'''
class C {}
enum E2 implements C {
  v
}
''');
    bFile.refresh();
    expect(
      fileSystemState.getFilesSubtypingName('A'),
      unorderedEquals([aFile]),
    );
    expect(
      fileSystemState.getFilesSubtypingName('C'),
      unorderedEquals([bFile]),
    );
  }

  test_getFilesSubtypingName_enum_with() {
    String a = convertPath('/a.dart');
    String b = convertPath('/b.dart');

    newFile(a, r'''
mixin M {}
enum E1 with M {
  v
}
''');
    newFile(b, r'''
mixin M {}
enum E2 with M {
  v
}
''');

    FileState aFile = fileSystemState.getFileForPath(a);
    FileState bFile = fileSystemState.getFileForPath(b);

    expect(
      fileSystemState.getFilesSubtypingName('M'),
      unorderedEquals([aFile, bFile]),
    );
  }

  test_hasUri() {
    Uri uri = Uri.parse('package:aaa/foo.dart');
    String templatePath = convertPath('/aaa/lib/foo.dart');
    String generatedPath = convertPath('/generated/aaa/lib/foo.dart');

    Source generatedSource = _SourceMock(generatedPath, uri);

    generatedUriResolver.resolveAbsoluteFunction = (uri) => generatedSource;

    expect(fileSystemState.hasUri(templatePath), isFalse);
    expect(fileSystemState.hasUri(generatedPath), isTrue);
  }

  test_referencedNames() {
    String path = convertPath('/aaa/lib/a.dart');
    newFile(path, r'''
A foo(B p) {
  foo(null);
  C c = new C(p);
  return c;
}
''');
    FileState file = fileSystemState.getFileForPath(path);
    expect(file.referencedNames, unorderedEquals(['A', 'B', 'C']));
  }

  test_refresh_differentApiSignature() {
    String path = convertPath('/aaa/lib/a.dart');
    newFile(path, r'''
class A {}
''');
    FileState file = fileSystemState.getFileForPath(path);
    expect(file.definedTopLevelNames, contains('A'));
    List<int> signature = file.apiSignature;

    // Update the resource and refresh the file state.
    newFile(path, r'''
class B {}
''');
    var changeKind = file.refresh();
    expect(changeKind, FileStateRefreshResult.apiChanged);

    expect(file.definedTopLevelNames, contains('B'));
    expect(file.apiSignature, isNot(signature));
  }

  test_refresh_sameApiSignature() {
    String path = convertPath('/aaa/lib/a.dart');
    newFile(path, r'''
class C {
  foo() {
    print(111);
  }
}
''');
    FileState file = fileSystemState.getFileForPath(path);
    List<int> signature = file.apiSignature;

    // Update the resource and refresh the file state.
    newFile(path, r'''
class C {
  foo() {
    print(222);
  }
}
''');
    var changeKind = file.refresh();
    expect(changeKind, FileStateRefreshResult.contentChanged);

    expect(file.apiSignature, signature);
  }

  test_store_zeroLengthUnlinked() {
    String path = convertPath('/test.dart');
    newFile(path, 'class A {}');

    // Get the file, prepare unlinked.
    FileState file = fileSystemState.getFileForPath(path);
    expect(file.unlinked2, isNotNull);

    // Make the unlinked unit in the byte store zero-length, damaged.
    byteStore.putGet(file.test.unlinkedKey, Uint8List(0));

    // Refresh should not fail, zero bytes in the store are ignored.
    file.refresh();
    expect(file.unlinked2, isNotNull);
  }

  test_subtypedNames() {
    String path = convertPath('/test.dart');
    newFile(path, r'''
class X extends A {}
class Y extends A with B {}
class Z implements C, D {}
''');
    FileState file = fileSystemState.getFileForPath(path);
    expect(file.referencedNames, unorderedEquals(['A', 'B', 'C', 'D']));
  }
}

class _GeneratedUriResolverMock extends UriResolver {
  Source? Function(Uri)? resolveAbsoluteFunction;

  Uri? Function(String)? pathToUriFunction;

  @override
  noSuchMethod(Invocation invocation) {
    throw StateError('Unexpected invocation of ${invocation.memberName}');
  }

  @override
  Uri? pathToUri(String path) {
    return pathToUriFunction?.call(path);
  }

  @override
  Source? resolveAbsolute(Uri uri) {
    if (resolveAbsoluteFunction != null) {
      return resolveAbsoluteFunction!(uri);
    }
    return null;
  }
}

class _SourceMock implements Source {
  @override
  final String fullName;

  @override
  final Uri uri;

  _SourceMock(this.fullName, this.uri);

  @override
  noSuchMethod(Invocation invocation) {
    throw StateError('Unexpected invocation of ${invocation.memberName}');
  }
}

extension on UriResolution? {
  FileState get file {
    return (this as UriResolutionFile).file;
  }
}
