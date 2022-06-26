// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/sdk/build_sdk_summary.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/feature_set_provider.dart';
import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/library_graph.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisOptions, AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/util/either.dart';
import 'package:analyzer/src/workspace/basic.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/context_collection_resolution.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FileSystemStateTest);
    defineReflectiveTests(FileSystemState_BazelWorkspaceTest);
    defineReflectiveTests(FileSystemState_PubPackageTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class FileSystemState_BazelWorkspaceTest extends BazelWorkspaceResolutionTest {
  void test_getFileForUri_hasGenerated_askGeneratedFirst() async {
    var relPath = 'dart/my/test/a.dart';
    var writablePath = convertPath('$workspaceRootPath/$relPath');
    var generatedPath = convertPath('$workspaceRootPath/bazel-bin/$relPath');

    // This generated file should be used instead of the writable.
    newFile(generatedPath, '');

    var analysisDriver = driverFor(convertPath(testFilePath));

    var fsState = analysisDriver.fsState;

    // Prepare URI(s).
    var generatedUri = toUri(generatedPath);
    var writableUri = toUri(writablePath);

    // The file is the generated file.
    var generatedFile = fsState.getFileForUri(generatedUri).t1!;
    expect(generatedFile.uri, writableUri);
    expect(generatedFile.path, generatedPath);

    // The file is cached under the requested URI.
    var writableFile1 = fsState.getFileForUri(writableUri).t1!;
    var writableFile2 = fsState.getFileForUri(writableUri).t1!;
    expect(writableFile1, same(generatedFile));
    expect(writableFile2, same(generatedFile));
  }

  void test_getFileForUri_hasGenerated_askWritableFirst() async {
    var relPath = 'dart/my/test/a.dart';
    var writablePath = convertPath('$workspaceRootPath/$relPath');
    var generatedPath = convertPath('$workspaceRootPath/bazel-bin/$relPath');

    // This generated file should be used instead of the writable.
    newFile(generatedPath, '');

    var analysisDriver = driverFor(convertPath(testFilePath));

    var fsState = analysisDriver.fsState;

    // Prepare URI(s).
    var generatedUri = toUri(generatedPath);
    var writableUri = toUri(writablePath);

    // The file is cached under the requested URI.
    var writableFile1 = fsState.getFileForUri(writableUri).t1!;
    var writableFile2 = fsState.getFileForUri(writableUri).t1!;
    expect(writableFile2, same(writableFile1));

    // The file is the generated file.
    var generatedFile = fsState.getFileForUri(generatedUri).t1!;
    expect(generatedFile.uri, writableUri);
    expect(generatedFile.path, generatedPath);
    expect(writableFile2, same(generatedFile));
  }

  void test_getFileForUri_nestedLib_notCanonicalUri() async {
    var outerPath = convertPath('$workspaceRootPath/my/outer/lib/a.dart');
    var outerUri = Uri.parse('package:my.outer/a.dart');

    var innerPath = convertPath('/workspace/my/outer/lib/inner/lib/b.dart');
    var innerUri = Uri.parse('package:my.outer.lib.inner/b.dart');

    var analysisDriver = driverFor(outerPath);
    var fsState = analysisDriver.fsState;

    // User code might use such relative URI.
    var innerUri2 = outerUri.resolve('inner/lib/b.dart');
    expect(innerUri2, Uri.parse('package:my.outer/inner/lib/b.dart'));

    // However the returned file must use the canonical URI.
    var innerFile = fsState.getFileForUri(innerUri2).t1!;
    expect(innerFile.path, innerPath);
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
    return fsStateFor(testFile).getFileForUri(uri).t1!;
  }

  FileState fileStateForUriStr(String uriStr) {
    final uri = Uri.parse(uriStr);
    return fileStateForUri(uri);
  }

  FileSystemState fsStateFor(File file) {
    return driverFor(file.path).fsState;
  }

  test_newFile_augmentation_augmentationExists_hasImport() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
import augment 'c.dart';
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
library augment 'b.dart';
''');

    fileStateFor(c);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        augmentations: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_2
        augmented: library_0
        library: library_0
        imports
          library_1 dart:core synthetic
        augmentations: file_2
      referencingFiles: [file_0]
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: augmentation_3
        augmented: augmentation_2
        library: library_0
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_1]
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_newFile_augmentation_augmentationExists_hasImport_disconnected() async {
    newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
import augment 'c.dart';
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
library augment 'b.dart';
''');

    fileStateFor(c);

    // `b.dart` points at `a.dart`, but `a.dart` does not import it.
    // So, we can resolve the file, but decline to consider it augmented.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_2
        uriFile: file_0
        imports
          library_1 dart:core synthetic
        augmentations: file_2
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: augmentation_3
        augmented: augmentation_2
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_1]
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_newFile_augmentation_augmentationExists_noImport() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
library augment 'b.dart';
''');

    fileStateFor(c);

    // `c.dart` points at `b.dart`, but `b.dart` does not import it.
    // So, we can resolve the file, but decline to consider it augmented.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        augmentations: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_2
        augmented: library_0
        library: library_0
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_0]
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: augmentation_3
        uriFile: file_1
        imports
          library_1 dart:core synthetic
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_newFile_augmentation_cycle1_augmentSelf() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
library augment 'b.dart';
import augment 'b.dart';
''');

    fileStateFor(a);

    // There is a cycle of augmentations from `b.dart` to itself.
    // This does not lead to a library, so it is absent.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        augmentations: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_2
        augmented: augmentation_2
        imports
          library_1 dart:core synthetic
        augmentations: file_1
      referencingFiles: [file_0, file_1]
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // The cycle does not prevent building of the library cycle. TODO
  }

  test_newFile_augmentation_cycle2() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
import augment 'c.dart';
''');

    newFile('$testPackageLibPath/c.dart', r'''
library augment 'b.dart';
import augment 'b.dart';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        augmentations: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_2
        augmented: library_0
        library: library_0
        imports
          library_1 dart:core synthetic
        augmentations: file_2
      referencingFiles: [file_0, file_2]
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: augmentation_3
        augmented: augmentation_2
        library: library_0
        imports
          library_1 dart:core synthetic
        augmentations: file_1
      referencingFiles: [file_1]
      unlinkedKey: k02
libraryCycles
elementFactory
''');

    // The cycle does not prevent building of the library cycle. TODO
  }

  test_newFile_augmentation_invalid() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library augment 'da:';
''');

    fileStateFor(a);

    // The URI is invalid, so there is no way to discover the target.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: augmentationUnknown_0
        uri: da:
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_augmentation_libraryExists_hasImport() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
''');

    fileStateFor(b);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        augmentations: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_2
        augmented: library_0
        library: library_0
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_0]
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_augmentation_libraryExists_noImport() async {
    final a = newFile('$testPackageLibPath/a.dart', '');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
''');

    fileStateFor(b);

    // We can find `a.dart` using the URI.
    // But it does not import the augmentation `b.dart`, so we find the
    // file that corresponds to the URI, but refuse to consider it augmented.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_2
        uriFile: file_0
        imports
          library_1 dart:core synthetic
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
      kind: library_3
        imports
          library_1 dart:core synthetic
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_2
        uriFile: file_0
        imports
          library_1 dart:core synthetic
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_augmentation_targetNotExists() async {
    final b = newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
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
        imports
          library_1 dart:core synthetic
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_2
        uriFile: file_0
        imports
          library_1 dart:core synthetic
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_augmentation_twoLibraries() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import augment 'c.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
import augment 'c.dart';
''');

    newFile('$testPackageLibPath/c.dart', r'''
library augment 'a.dart';
''');

    final aState = fileStateFor(a);

    // We use the URI from `library augment` to find the augmentation target.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        augmentations: file_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: augmentation_2
        augmented: library_0
        library: library_0
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_0]
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Reading `b.dart` does not update the augmentation.
    final bState = fileStateFor(b);
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        augmentations: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_2
      kind: library_3
        imports
          library_1 dart:core synthetic
        augmentations: file_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: augmentation_2
        augmented: library_0
        library: library_0
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_0, file_2]
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Refreshing `b.dart` does not update the augmentation.
    bState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        augmentations: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_2
      kind: library_4
        imports
          library_1 dart:core synthetic
        augmentations: file_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: augmentation_2
        augmented: library_0
        library: library_0
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_0, file_2]
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Exclude from `a.dart`, the URI still points at `a.dart`.
    // But `c.dart` is not a valid augmentation anymore.
    newFile(a.path, '');
    aState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_5
        imports
          library_1 dart:core synthetic
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_2
      kind: library_4
        imports
          library_1 dart:core synthetic
        augmentations: file_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: augmentation_2
        uriFile: file_0
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_2]
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Exclude from `b.dart`, still point at `a.dart`, still not valid.
    newFile(b.path, '');
    bState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_5
        imports
          library_1 dart:core synthetic
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_2
      kind: library_6
        imports
          library_1 dart:core synthetic
      unlinkedKey: k02
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: augmentation_2
        uriFile: file_0
        imports
          library_1 dart:core synthetic
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Include into `b.dart`, still point at `a.dart`, still not valid.
    newFile(b.path, r'''
import augment 'c.dart';
''');
    bState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_5
        imports
          library_1 dart:core synthetic
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_2
      kind: library_7
        imports
          library_1 dart:core synthetic
        augmentations: file_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: augmentation_2
        uriFile: file_0
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_2]
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Include into `a.dart`, restore to `a.dart` as the target.
    newFile(a.path, r'''
import augment 'c.dart';
''');
    aState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_8
        imports
          library_1 dart:core synthetic
        augmentations: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_2
      kind: library_7
        imports
          library_1 dart:core synthetic
        augmentations: file_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: augmentation_2
        augmented: library_8
        library: library_8
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_0, file_2]
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_doesNotExist() {
    final a = getFile('$testPackageLibPath/a.dart');

    final file = fileStateFor(a);
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
        imports
          library_1 dart:core synthetic
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_exports_augmentation() async {
    newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
export 'b.dart';
''');

    fileStateFor(c);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_2
        uriFile: file_0
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_2]
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_3
        imports
          library_1 dart:core synthetic
        exports
          notLibrary file_1
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_newFile_library_exports_dart() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
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
        imports
          library_1 dart:core synthetic
        exports
          library_2 dart:async
          library_3 dart:math
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_exports_inSummary_library() async {
    // Prepare a bundle where `package:foo/foo.dart` is a library.
    final librarySummaryFiles = <File>[];
    {
      final fooRoot = getFolder('$workspaceRootPath/foo');

      newFile('${fooRoot.path}/lib/foo.dart', 'class F {}');

      final fooPackageConfigFile = getFile(
        '${fooRoot.path}/.dart_tool/package_config.json',
      );

      writePackageConfig(
        fooPackageConfigFile.path,
        PackageConfigFileBuilder()..add(name: 'foo', rootPath: fooRoot.path),
      );

      final analysisDriver = driverFor(fooRoot.path);
      final bundleBytes = await analysisDriver.buildPackageBundle(
        uriList: [
          Uri.parse('package:foo/foo.dart'),
        ],
      );

      final bundleFile = getFile('/home/summaries/packages.sum');
      bundleFile.writeAsBytesSync(bundleBytes);

      librarySummaryFiles.add(bundleFile);

      // Delete, so it is not available as a file.
      // We don't have a package config for it anyway, but just to be sure.
      fooRoot.delete();
    }

    // Prepare for recreating the collection, with summaries.
    sdkSummaryFile = await _writeSdkSummary();
    this.librarySummaryFiles = librarySummaryFiles;

    disposeAnalysisContextCollection();

    final a = newFile('$testPackageLibPath/a.dart', r'''
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
        imports
          inSummary dart:core synthetic
        exports
          inSummary dart:async
          inSummary package:foo/foo.dart
          library_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        imports
          inSummary dart:core synthetic
      referencingFiles: [file_0]
      unlinkedKey: k01
libraryCycles
elementFactory
  hasReader
    package:foo/foo.dart
''');
  }

  test_newFile_library_exports_inSummary_part() async {
    // Prepare a bundle where `package:foo/foo2.dart` is a part.
    final librarySummaryFiles = <File>[];
    {
      final fooRoot = getFolder('$workspaceRootPath/foo');

      newFile('${fooRoot.path}/lib/foo.dart', r'''
part 'foo2.dart';
''');

      newFile('${fooRoot.path}/lib/foo2.dart', r'''
part of 'foo.dart';
''');

      final fooPackageConfigFile = getFile(
        '${fooRoot.path}/.dart_tool/package_config.json',
      );

      writePackageConfig(
        fooPackageConfigFile.path,
        PackageConfigFileBuilder()..add(name: 'foo', rootPath: fooRoot.path),
      );

      final analysisDriver = driverFor(fooRoot.path);
      final bundleBytes = await analysisDriver.buildPackageBundle(
        uriList: [
          Uri.parse('package:foo/foo.dart'),
        ],
      );

      final bundleFile = getFile('/home/summaries/packages.sum');
      bundleFile.writeAsBytesSync(bundleBytes);

      librarySummaryFiles.add(bundleFile);

      // Delete, so it is not available as a file.
      // We don't have a package config for it anyway, but just to be sure.
      fooRoot.delete();
    }

    // Prepare for recreating the collection, with summaries.
    sdkSummaryFile = await _writeSdkSummary();
    this.librarySummaryFiles = librarySummaryFiles;

    disposeAnalysisContextCollection();

    final a = newFile('$testPackageLibPath/a.dart', r'''
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
        imports
          inSummary dart:core synthetic
        exports
          inSummary package:foo/foo2.dart notLibrary
          library_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        imports
          inSummary dart:core synthetic
      referencingFiles: [file_0]
      unlinkedKey: k01
libraryCycles
elementFactory
  hasReader
    package:foo/foo.dart
''');
  }

  test_newFile_library_exports_invalidRelativeUri() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
export 'net:';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        exports
          uri: net:
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_exports_package() async {
    final c = newFile('$testPackageLibPath/c.dart', r'''
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
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_2]
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_2
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_2]
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_3
        imports
          library_1 dart:core synthetic
        exports
          library_0
          library_2
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_library_exports_part() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of my.lib;
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
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
      referencingFiles: [file_1]
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        imports
          library_2 dart:core synthetic
        exports
          notLibrary file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_library_imports_augmentation() async {
    newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
import 'b.dart';
''');

    fileStateFor(c);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_2
        uriFile: file_0
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_2]
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_3
        imports
          notLibrary file_1
          library_1 dart:core synthetic
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_newFile_library_imports_invalidRelativeUri() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import 'da:';
''');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          uri: da:
          library_1 dart:core synthetic
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_imports_library_dart() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
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
        imports
          library_1 dart:async
          library_2 dart:math
          library_3 dart:core synthetic
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_imports_library_dart_explicitDartCore() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
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
        imports
          library_1 dart:core
          library_2 dart:math
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_library_imports_library_inSummary_library() async {
    // Prepare a bundle where `package:foo/foo.dart` is a library.
    final librarySummaryFiles = <File>[];
    {
      final fooRoot = getFolder('$workspaceRootPath/foo');

      newFile('${fooRoot.path}/lib/foo.dart', 'class F {}');

      final fooPackageConfigFile = getFile(
        '${fooRoot.path}/.dart_tool/package_config.json',
      );

      writePackageConfig(
        fooPackageConfigFile.path,
        PackageConfigFileBuilder()..add(name: 'foo', rootPath: fooRoot.path),
      );

      final analysisDriver = driverFor(fooRoot.path);
      final bundleBytes = await analysisDriver.buildPackageBundle(
        uriList: [
          Uri.parse('package:foo/foo.dart'),
        ],
      );

      final bundleFile = getFile('/home/summaries/packages.sum');
      bundleFile.writeAsBytesSync(bundleBytes);

      librarySummaryFiles.add(bundleFile);

      // Delete, so it is not available as a file.
      // We don't have a package config for it anyway, but just to be sure.
      fooRoot.delete();
    }

    // Prepare for recreating the collection, with summaries.
    sdkSummaryFile = await _writeSdkSummary();
    this.librarySummaryFiles = librarySummaryFiles;

    disposeAnalysisContextCollection();

    final a = newFile('$testPackageLibPath/a.dart', r'''
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
        imports
          inSummary dart:async
          inSummary package:foo/foo.dart
          library_1
          inSummary dart:core synthetic
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        imports
          inSummary dart:core synthetic
      referencingFiles: [file_0]
      unlinkedKey: k01
libraryCycles
elementFactory
  hasReader
    package:foo/foo.dart
''');
  }

  test_newFile_library_imports_library_inSummary_part() async {
    // Prepare a bundle where `package:foo/foo2.dart` is a part.
    final librarySummaryFiles = <File>[];
    {
      final fooRoot = getFolder('$workspaceRootPath/foo');

      newFile('${fooRoot.path}/lib/foo.dart', r'''
part 'foo2.dart';
''');

      newFile('${fooRoot.path}/lib/foo2.dart', r'''
part of 'foo.dart';
''');

      final fooPackageConfigFile = getFile(
        '${fooRoot.path}/.dart_tool/package_config.json',
      );

      writePackageConfig(
        fooPackageConfigFile.path,
        PackageConfigFileBuilder()..add(name: 'foo', rootPath: fooRoot.path),
      );

      final analysisDriver = driverFor(fooRoot.path);
      final bundleBytes = await analysisDriver.buildPackageBundle(
        uriList: [
          Uri.parse('package:foo/foo.dart'),
        ],
      );

      final bundleFile = getFile('/home/summaries/packages.sum');
      bundleFile.writeAsBytesSync(bundleBytes);

      librarySummaryFiles.add(bundleFile);

      // Delete, so it is not available as a file.
      // We don't have a package config for it anyway, but just to be sure.
      fooRoot.delete();
    }

    // Prepare for recreating the collection, with summaries.
    sdkSummaryFile = await _writeSdkSummary();
    this.librarySummaryFiles = librarySummaryFiles;

    disposeAnalysisContextCollection();

    final a = newFile('$testPackageLibPath/a.dart', r'''
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
        imports
          inSummary package:foo/foo2.dart notLibrary
          library_1
          inSummary dart:core synthetic
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        imports
          inSummary dart:core synthetic
      referencingFiles: [file_0]
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

    final c = newFile('$testPackageLibPath/c.dart', r'''
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
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_2]
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_2
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_2]
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_3
        imports
          library_0
          library_2
          library_1 dart:core synthetic
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_library_imports_part() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of my.lib;
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
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
      referencingFiles: [file_1]
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        imports
          notLibrary file_0
          library_2 dart:core synthetic
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_library_includePart_withoutPartOf() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
// no part of
''');

    final aState = fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_2
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_0]
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
      kind: library_3
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_2
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_0]
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_libraryDirective() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
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
        imports
          library_1 dart:core synthetic
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_noDirectives() async {
    final a = newFile('$testPackageLibPath/a.dart', '');

    fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  /// TODO(scheglov) Test discovery of a sibling library
  test_newFile_partOfName() async {
    final a = newFile('$testPackageLibPath/nested/a.dart', r'''
library my.lib;
part '../b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
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
      referencingFiles: [file_1]
      unlinkedKey: k00
  /home/test/lib/nested/a.dart
    uri: package:test/nested/a.dart
    current
      id: file_1
      kind: library_1
        name: my.lib
        imports
          library_2 dart:core synthetic
        parts: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfName_differentName() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library my.lib;
part 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of other.lib;
''');

    fileStateFor(b);

    // We don't know the library initially.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_0
      kind: partOfName_0
        name: other.lib
      referencingFiles: [file_1]
      unlinkedKey: k00
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
      id: file_1
      kind: library_1
        name: my.lib
        imports
          library_2 dart:core synthetic
        parts: file_0
      unlinkedKey: k01
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_0
      kind: partOfName_0
        name: other.lib
      referencingFiles: [file_1]
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfName_twoLibraries() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library my.lib;
part 'c.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library my.lib;
part 'c.dart';
''');

    newFile('$testPackageLibPath/c.dart', r'''
part of my.lib;
''');

    final aState = fileStateFor(a);

    // When reading `a.dart` we also read `c.dart` part.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my.lib
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfName_2
        libraries: library_0
        library: library_0
      referencingFiles: [file_0]
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // After reading `b.dart` the part has two libraries to choose from.
    // We still keep `a.dart`, because its path is sorted first.
    final bState = fileStateFor(b);
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my.lib
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_2
      kind: library_3
        name: my.lib
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfName_2
        libraries: library_0 library_3
        library: library_0
      referencingFiles: [file_0, file_2]
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
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_2
      kind: library_4
        name: my.lib
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfName_2
        libraries: library_0 library_4
        library: library_0
      referencingFiles: [file_0, file_2]
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
      kind: library_5
        name: my.lib
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_2
      kind: library_4
        name: my.lib
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfName_2
        libraries: library_4 library_5
        library: library_5
      referencingFiles: [file_0, file_2]
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
      kind: library_6
        imports
          library_1 dart:core synthetic
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_2
      kind: library_4
        name: my.lib
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfName_2
        libraries: library_4
        library: library_4
      referencingFiles: [file_2]
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
      kind: library_6
        imports
          library_1 dart:core synthetic
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_2
      kind: library_7
        imports
          library_1 dart:core synthetic
      unlinkedKey: k02
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfName_2
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
      kind: library_6
        imports
          library_1 dart:core synthetic
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_2
      kind: library_8
        name: my.lib
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfName_2
        libraries: library_8
        library: library_8
      referencingFiles: [file_2]
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
      kind: library_9
        name: my.lib
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_2
      kind: library_8
        name: my.lib
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfName_2
        libraries: library_8 library_9
        library: library_9
      referencingFiles: [file_0, file_2]
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfUri_doesNotExist() async {
    final a = getFile('$testPackageLibPath/a.dart');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    final bState = fileStateFor(b);

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
        imports
          library_1 dart:core synthetic
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_2
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
    final aState = fileStateFor(a);
    aState.refresh();

    // Now the part file knows its library.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_3
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_2
        library: library_3
      referencingFiles: [file_0]
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
      kind: library_3
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_4
        library: library_3
      referencingFiles: [file_0]
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfUri_exists_hasPart() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    final bState = fileStateFor(b);

    // We have not read the library file explicitly yet.
    // But it was read because of the `part of` directive.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_2
        library: library_0
      referencingFiles: [file_0]
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
      kind: library_0
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_3
        library: library_0
      referencingFiles: [file_0]
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfUri_exists_noPart() async {
    final a = newFile('$testPackageLibPath/a.dart', '');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    fileStateFor(a);
    fileStateFor(b);

    // The URI in `part of URI` tells us which library to use.
    // However `a.dart` does not include `b.dart` as a part, so `b.dart` will
    // not be analyzed during the library analysis.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_2
        uriFile: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfUri_invalid() async {
    final b = newFile('$testPackageLibPath/b.dart', r'''
part of 'da:';
''');

    fileStateFor(b);

    // The URI is invalid, so there is no way to discover the library.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_0
      kind: partOfUriUnknown_0
        uri: da:
      unlinkedKey: k00
libraryCycles
elementFactory
''');

    // Reading a library that includes this part does not change the fact
    // that the URI in the `part of URI` in `b.dart` cannot be resolved.
    final a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');
    fileStateFor(a);
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_1
      kind: library_1
        imports
          library_2 dart:core synthetic
        parts: file_0
      unlinkedKey: k01
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_0
      kind: partOfUriUnknown_0
        uri: da:
      referencingFiles: [file_1]
      unlinkedKey: k00
libraryCycles
elementFactory
''');
  }

  test_newFile_partOfUri_twoLibraries() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part 'c.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part 'c.dart';
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
part of 'a.dart';
''');

    final aState = fileStateFor(a);
    _assertPartedFiles(aState, [c]);

    // We set the library while reading `a.dart` file.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfUriKnown_2
        library: library_0
      referencingFiles: [file_0]
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Reading `b.dart` does not update the part.
    final bState = fileStateFor(b);
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_2
      kind: library_3
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfUriKnown_2
        library: library_0
      referencingFiles: [file_0, file_2]
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
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_2
      kind: library_4
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfUriKnown_2
        library: library_0
      referencingFiles: [file_0, file_2]
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
      kind: library_5
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_2
      kind: library_4
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfUriKnown_2
        library: library_5
      referencingFiles: [file_0, file_2]
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
      kind: library_6
        imports
          library_1 dart:core synthetic
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_2
      kind: library_4
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfUriKnown_2
        uriFile: file_0
      referencingFiles: [file_2]
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
      kind: library_6
        imports
          library_1 dart:core synthetic
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_2
      kind: library_7
        imports
          library_1 dart:core synthetic
      unlinkedKey: k02
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfUriKnown_2
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
      kind: library_6
        imports
          library_1 dart:core synthetic
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_2
      kind: library_8
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfUriKnown_2
        uriFile: file_0
      referencingFiles: [file_2]
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
      kind: library_9
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_2
      kind: library_8
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_1
      kind: partOfUriKnown_2
        library: library_9
      referencingFiles: [file_0, file_2]
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_refresh_augmentation_to_library() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
''');

    final aState = fileStateFor(a);
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        augmentations: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_2
        augmented: library_0
        library: library_0
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_0]
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Make it a library.
    newFile(b.path, '');
    fileStateFor(b).refresh();

    // Not an augmentation anymore, but a library.
    // But `a.dart` still uses `b.dart` as an augmentation.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        augmentations: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_3
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_0]
      unlinkedKey: k02
libraryCycles
elementFactory
''');

    // ...even if we attempt to refresh.
    aState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_4
        imports
          library_1 dart:core synthetic
        augmentations: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_3
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_0]
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_refresh_augmentation_to_partOfName() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library my.lib;
import augment 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
''');

    final aState = fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my.lib
        imports
          library_1 dart:core synthetic
        augmentations: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_2
        augmented: library_0
        library: library_0
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_0]
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Make it a part.
    newFile(b.path, r'''
part of my.lib;
''');

    // Not an augmentation anymore, but a part.
    // This part can find the referenced library by name `my.lib`.
    // But the library does not include this part, so no library.
    //
    // But `a.dart` still uses `b.dart` as an augmentation.
    final bState = fileStateFor(b);
    bState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my.lib
        imports
          library_1 dart:core synthetic
        augmentations: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfName_3
        libraries: library_0
        name: my.lib
      referencingFiles: [file_0]
      unlinkedKey: k02
libraryCycles
elementFactory
''');

    // ...even if we attempt to refresh.
    aState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_4
        name: my.lib
        imports
          library_1 dart:core synthetic
        augmentations: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfName_3
        libraries: library_4
        name: my.lib
      referencingFiles: [file_0]
      unlinkedKey: k02
libraryCycles
elementFactory
''');

    // Now include `b.dart` into `a.dart` as a part.
    newFile(a.path, r'''
library my.lib;
part 'b.dart';
''');
    aState.refresh();

    // ...not an augmentation, but a known part.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_5
        name: my.lib
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k03
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfName_3
        libraries: library_5
        library: library_5
      referencingFiles: [file_0]
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_refresh_augmentation_to_partOfUri() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
''');

    final aState = fileStateFor(a);
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        augmentations: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_2
        augmented: library_0
        library: library_0
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_0]
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Make it a part.
    newFile(b.path, r'''
part of 'a.dart';
''');

    // Not an augmentation anymore, but a part.
    // But `a.dart` still uses `b.dart` as an augmentation.
    final bState = fileStateFor(b);
    bState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        augmentations: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_3
        uriFile: file_0
      referencingFiles: [file_0]
      unlinkedKey: k02
libraryCycles
elementFactory
''');

    // ...even if we attempt to refresh.
    aState.refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_4
        imports
          library_1 dart:core synthetic
        augmentations: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_3
        uriFile: file_0
      referencingFiles: [file_0]
      unlinkedKey: k02
libraryCycles
elementFactory
''');

    // Now include `b.dart` into `a.dart` as a part.
    newFile(a.path, r'''
part 'b.dart';
''');
    aState.refresh();

    // ...not an augmentation, but a known part.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_5
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k03
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_3
        library: library_5
      referencingFiles: [file_0]
      unlinkedKey: k02
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

    final c = newFile('$testPackageLibPath/c.dart', r'''
library my;
part 'a.dart';
part 'b.dart';
''');

    final cState = fileStateFor(c);

    // Both part files know the library.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfName_0
        libraries: library_1
        library: library_1
      referencingFiles: [file_2]
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfName_2
        libraries: library_1
        library: library_1
      referencingFiles: [file_2]
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_1
        name: my
        imports
          library_3 dart:core synthetic
        parts: file_0 file_1
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
        libraries: library_4
        name: my
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfName_2
        libraries: library_4
        library: library_4
      referencingFiles: [file_2]
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_4
        name: my
        imports
          library_3 dart:core synthetic
        parts: file_1
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

    final c = newFile('$testPackageLibPath/c.dart', r'''
part 'a.dart';
part 'b.dart';
''');

    final cState = fileStateFor(c);

    // Both part files know the library.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfUriKnown_0
        library: library_1
      referencingFiles: [file_2]
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_2
        library: library_1
      referencingFiles: [file_2]
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_1
        imports
          library_3 dart:core synthetic
        parts: file_0 file_1
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
      kind: partOfUriKnown_2
        library: library_4
      referencingFiles: [file_2]
      unlinkedKey: k00
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_4
        name: my
        imports
          library_3 dart:core synthetic
        parts: file_1
      unlinkedKey: k02
libraryCycles
elementFactory
''');
  }

  test_refresh_library_to_augmentation() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
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
        imports
          library_1 dart:core synthetic
        augmentations: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_2
        name: b
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_0]
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    newFile(b.path, r'''
library augment 'a.dart';
''');

    // We will discover the target by URI.
    fileStateFor(b).refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        augmentations: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: augmentation_3
        augmented: library_0
        library: library_0
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_0]
      unlinkedKey: k02
libraryCycles
elementFactory
''');

    // The file `b.dart` was something else, but now it is a known augmentation.
    // This affects libraries that include it.
    // TODO(scheglov) Restore.
    // final aCycle_2 = aState.libraryCycle;
    // expect(aCycle_2.apiSignature, isNot(aCycle_1.apiSignature));
  }

  test_refresh_library_to_partOfName() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library my.lib;
part 'b.dart';
''');

    // No `part of`, so it is a library.
    final b = newFile('$testPackageLibPath/b.dart', '');

    final aState = fileStateFor(a);
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my.lib
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_2
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_0]
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    final aCycle_1 = aState.libraryCycle;

    // Make it a part.
    newFile(b.path, r'''
part of my.lib;
''');

    // We will discover the library by name.
    fileStateFor(b).refresh();

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my.lib
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfName_3
        libraries: library_0
        library: library_0
      referencingFiles: [file_0]
      unlinkedKey: k02
libraryCycles
elementFactory
''');

    // The file `b.dart` was something else, but now it is a known part.
    // This affects libraries that include it.
    final aCycle_2 = aState.libraryCycle;
    expect(aCycle_2.apiSignature, isNot(aCycle_1.apiSignature));
  }

  test_refresh_library_to_partOfName_noLibrary() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library my;
''');

    final aState = fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        name: my
        imports
          library_1 dart:core synthetic
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
      kind: partOfName_2
        name: my
      unlinkedKey: k01
libraryCycles
elementFactory
''');
  }

  test_refresh_library_to_partOfUri() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library b;
''');

    final aState = fileStateFor(a);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_2
        name: b
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_0]
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    final aCycle_1 = aState.libraryCycle;

    newFile(b.path, r'''
part of 'a.dart';
''');

    // We will discover the library using the URI.
    fileStateFor(b).refresh();
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_3
        library: library_0
      referencingFiles: [file_0]
      unlinkedKey: k02
libraryCycles
elementFactory
''');

    // The file `b.dart` was something else, but now it is a known part.
    // This affects libraries that include it.
    final aCycle_2 = aState.libraryCycle;
    expect(aCycle_2.apiSignature, isNot(aCycle_1.apiSignature));
  }

  test_refresh_partOfName_twoLibraries() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part of my.lib;
class A1 {}
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library my.lib;
part 'a.dart';
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
library my.lib;
part 'a.dart';
''');

    final bState = fileStateFor(b);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfName_0
        libraries: library_1
        library: library_1
      referencingFiles: [file_1]
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        name: my.lib
        imports
          library_2 dart:core synthetic
        parts: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // Get `c.dart`, not there are two libraries to chose from.
    final cState = fileStateFor(c);
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfName_0
        libraries: library_1 library_3
        library: library_1
      referencingFiles: [file_1, file_2]
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        name: my.lib
        imports
          library_2 dart:core synthetic
        parts: file_0
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_3
        name: my.lib
        imports
          library_2 dart:core synthetic
        parts: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    final bCycle_1 = bState.libraryCycle;
    final cCycle_1 = cState.libraryCycle;

    // Update `a.dart` part.
    newFile(a.path, r'''
part of my.lib;
class A2 {}
''');
    fileStateFor(a).refresh();

    // `a.dart` is still a part.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfName_4
        libraries: library_1 library_3
        library: library_1
      referencingFiles: [file_1, file_2]
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        name: my.lib
        imports
          library_2 dart:core synthetic
        parts: file_0
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_3
        name: my.lib
        imports
          library_2 dart:core synthetic
        parts: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // ...but the unlinked signature of `a.dart` is different.
    // We invalidate `b.dart` it references `a.dart`.
    // We invalidate `c.dart` it references `a.dart`.
    // Even though `a.dart` is not a valid part of `c.dart`.
    final bCycle_2 = bState.libraryCycle;
    final cCycle_2 = cState.libraryCycle;
    expect(bCycle_2.apiSignature, isNot(bCycle_1.apiSignature));
    expect(cCycle_2.apiSignature, isNot(cCycle_1.apiSignature));
  }

  test_refresh_partOfUri_to_library() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    final aState = fileStateFor(a);

    // There is `part of` in `b.dart`, so it is a part.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: partOfUriKnown_2
        library: library_0
      referencingFiles: [file_0]
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    final aCycle_1 = aState.libraryCycle;

    newFile(b.path, r'''
// no part of
''');
    fileStateFor(b).refresh();

    // There are no directives in `b.dart`, so it is a library.
    // Library `a.dart` still considers `b.dart` its part.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        imports
          library_1 dart:core synthetic
        parts: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_3
        imports
          library_1 dart:core synthetic
      referencingFiles: [file_0]
      unlinkedKey: k02
libraryCycles
elementFactory
''');

    // The library cycle for `a.dart` is different now.
    final aCycle_2 = aState.libraryCycle;
    expect(aCycle_2.apiSignature, isNot(aCycle_1.apiSignature));
  }

  test_refresh_partOfUri_twoLibraries() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part of 'b.dart';
class A1 {}
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part 'a.dart';
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
part 'a.dart';
''');

    final bState = fileStateFor(b);

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfUriKnown_0
        library: library_1
      referencingFiles: [file_1]
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        imports
          library_2 dart:core synthetic
        parts: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    final cState = fileStateFor(c);
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfUriKnown_0
        library: library_1
      referencingFiles: [file_1, file_2]
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        imports
          library_2 dart:core synthetic
        parts: file_0
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_3
        imports
          library_2 dart:core synthetic
        parts: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    final bCycle_1 = bState.libraryCycle;
    final cCycle_1 = cState.libraryCycle;

    // Update `a.dart` part.
    newFile(a.path, r'''
part of 'b.dart';
class A2 {}
''');

    fileStateFor(a).refresh();

    // `a.dart` is still a part.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: partOfUriKnown_4
        library: library_1
      referencingFiles: [file_1, file_2]
      unlinkedKey: k02
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        imports
          library_2 dart:core synthetic
        parts: file_0
      unlinkedKey: k01
  /home/test/lib/c.dart
    uri: package:test/c.dart
    current
      id: file_2
      kind: library_3
        imports
          library_2 dart:core synthetic
        parts: file_0
      unlinkedKey: k01
libraryCycles
elementFactory
''');

    // ...but the unlinked signature of `a.dart` is different.
    // We invalidate `b.dart` it references `a.dart`.
    // We invalidate `c.dart` it references `a.dart`.
    // Even though `a.dart` is not a valid part of `c.dart`.
    // TODO(scheglov) Change all signature checks to the dump.
    final bCycle_2 = bState.libraryCycle;
    final cCycle_2 = cState.libraryCycle;
    expect(bCycle_2.apiSignature, isNot(bCycle_1.apiSignature));
    expect(cCycle_2.apiSignature, isNot(cCycle_1.apiSignature));
  }

  void _assertPartedFiles(FileState fileState, List<File> expected) {
    final actualFiles = fileState.partedFiles.map((part) {
      if (part != null) {
        return getFile(part.path);
      }
    }).toList();
    expect(actualFiles, expected);
  }

  Future<File> _writeSdkSummary() async {
    final file = getFile('/home/summaries/sdk.sum');
    final bytes = await buildSdkSummary2(
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
    );
    file.writeAsBytesSync(bytes);
    return file;
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

    AnalysisOptions analysisOptions = AnalysisOptionsImpl();
    var featureSetProvider = FeatureSetProvider.build(
      sourceFactory: sourceFactory,
      resourceProvider: resourceProvider,
      packages: Packages.empty,
      packageDefaultFeatureSet: FeatureSet.latestLanguageVersion(),
      nonPackageDefaultLanguageVersion: ExperimentStatus.currentVersion,
      nonPackageDefaultFeatureSet: FeatureSet.latestLanguageVersion(),
    );
    fileSystemState = FileSystemState(
      logger,
      byteStore,
      resourceProvider,
      'contextName',
      sourceFactory,
      workspace,
      analysisOptions,
      DeclaredVariables(),
      Uint32List(0),
      Uint32List(0),
      featureSetProvider,
      fileContentStrategy: StoredFileContentStrategy(
        FileContentCache.ephemeral(resourceProvider),
      ),
      prefetchFiles: null,
      isGenerated: (_) => false,
      testData: null,
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

  test_getFileForPath_emptyUri() {
    String path = convertPath('/test.dart');
    newFile(path, r'''
import '';
export '';
part '';
''');

    FileState file = fileSystemState.getFileForPath(path);
    _assertIsUnresolvedFile(file.importedFiles[0]);
    _assertIsUnresolvedFile(file.exportedFiles[0]);
    _assertIsUnresolvedFile(file.partedFiles[0]);
  }

  test_getFileForPath_hasLibraryDirective_hasPartOfDirective() {
    String a = convertPath('/test/lib/a.dart');
    newFile(a, r'''
library L;
part of L;
''');
    FileState file = fileSystemState.getFileForPath(a);
    expect(file.isPart, isFalse);
  }

  test_getFileForPath_invalidUri() {
    String a = convertPath('/aaa/lib/a.dart');
    String a1 = convertPath('/aaa/lib/a1.dart');
    String a2 = convertPath('/aaa/lib/a2.dart');
    String a3 = convertPath('/aaa/lib/a3.dart');
    String content_a1 = r'''
import 'package:aaa/a1.dart';
import ':[invalid uri]';

export 'package:aaa/a2.dart';
export ':[invalid uri]';

part 'a3.dart';
part ':[invalid uri]';
''';
    newFile(a, content_a1);

    FileState file = fileSystemState.getFileForPath(a);

    expect(_excludeSdk(file.importedFiles), hasLength(2));
    expect(file.importedFiles[0]!.path, a1);
    expect(file.importedFiles[0]!.uri, Uri.parse('package:aaa/a1.dart'));
    expect(file.importedFiles[0]!.source, isNotNull);
    _assertIsUnresolvedFile(file.importedFiles[1]);

    expect(_excludeSdk(file.exportedFiles), hasLength(2));
    expect(file.exportedFiles[0]!.path, a2);
    expect(file.exportedFiles[0]!.uri, Uri.parse('package:aaa/a2.dart'));
    expect(file.exportedFiles[0]!.source, isNotNull);
    _assertIsUnresolvedFile(file.exportedFiles[1]);

    expect(_excludeSdk(file.partedFiles), hasLength(2));
    expect(file.partedFiles[0]!.path, a3);
    expect(file.partedFiles[0]!.uri, Uri.parse('package:aaa/a3.dart'));
    expect(file.partedFiles[0]!.source, isNotNull);
    _assertIsUnresolvedFile(file.partedFiles[1]);
  }

  test_getFileForPath_onlyDartFiles() {
    String not_dart = convertPath('/test/lib/not_dart.txt');
    String a = convertPath('/test/lib/a.dart');
    String b = convertPath('/test/lib/b.dart');
    String c = convertPath('/test/lib/c.dart');
    String d = convertPath('/test/lib/d.dart');
    newFile(a, r'''
library lib;
import 'dart:math';
import 'b.dart';
import 'not_dart.txt';
export 'c.dart';
export 'not_dart.txt';
part 'd.dart';
part 'not_dart.txt';
''');
    FileState file = fileSystemState.getFileForPath(a);
    expect(_excludeSdk(file.importedFiles).map((f) => f!.path), [b, not_dart]);
    expect(file.exportedFiles.map((f) => f!.path), [c, not_dart]);
    expect(file.partedFiles.map((f) => f!.path), [d, not_dart]);
    expect(_excludeSdk(fileSystemState.knownFilePaths),
        unorderedEquals([a, b, c, d, not_dart]));
  }

  test_getFileForPath_samePath() {
    String path = convertPath('/aaa/lib/a.dart');
    FileState file1 = fileSystemState.getFileForPath(path);
    FileState file2 = fileSystemState.getFileForPath(path);
    expect(file2, same(file1));
  }

  test_getFileForUri_invalidUri() {
    var uri = Uri.parse('package:x');
    fileSystemState.getFileForUri(uri).map(
      (file) {
        expect(file, isNull);
      },
      (_) {
        fail('Expected null.');
      },
    );
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

  test_libraryCycle() {
    String pa = convertPath('/aaa/lib/a.dart');
    String pb = convertPath('/aaa/lib/b.dart');
    String pc = convertPath('/aaa/lib/c.dart');
    String pd = convertPath('/aaa/lib/d.dart');

    FileState fa = fileSystemState.getFileForPath(pa);
    FileState fb = fileSystemState.getFileForPath(pb);
    FileState fc = fileSystemState.getFileForPath(pc);
    FileState fd = fileSystemState.getFileForPath(pd);

    // Compute library cycles for all files.
    fa.libraryCycle;
    fb.libraryCycle;
    fc.libraryCycle;
    fd.libraryCycle;
    _assertFilesWithoutLibraryCycle([]);

    // No imports, so just a single file.
    newFile(pa, '');
    _assertLibraryCycle(fa, [fa], []);

    // Import b.dart into a.dart, two files now.
    newFile(pa, "import 'b.dart';");
    fa.refresh();
    _assertFilesWithoutLibraryCycle([fa]);
    _assertLibraryCycle(fa, [fa], [fb.libraryCycle]);

    // Update b.dart so that it imports c.dart now.
    newFile(pb, "import 'c.dart';");
    fb.refresh();
    _assertFilesWithoutLibraryCycle([fa, fb]);
    _assertLibraryCycle(fa, [fa], [fb.libraryCycle]);
    _assertLibraryCycle(fb, [fb], [fc.libraryCycle]);
    _assertFilesWithoutLibraryCycle([]);

    // Update b.dart so that it exports d.dart instead.
    newFile(pb, "export 'd.dart';");
    fb.refresh();
    _assertFilesWithoutLibraryCycle([fa, fb]);
    _assertLibraryCycle(fa, [fa], [fb.libraryCycle]);
    _assertLibraryCycle(fb, [fb], [fd.libraryCycle]);
    _assertFilesWithoutLibraryCycle([]);

    // Update a.dart so that it does not import b.dart anymore.
    newFile(pa, '');
    fa.refresh();
    _assertFilesWithoutLibraryCycle([fa]);
    _assertLibraryCycle(fa, [fa], []);
  }

  test_libraryCycle_cycle() {
    String pa = convertPath('/aaa/lib/a.dart');
    String pb = convertPath('/aaa/lib/b.dart');

    newFile(pa, "import 'b.dart';");
    newFile(pb, "import 'a.dart';");

    FileState fa = fileSystemState.getFileForPath(pa);
    FileState fb = fileSystemState.getFileForPath(pb);

    // Compute library cycles for all files.
    fa.libraryCycle;
    fb.libraryCycle;
    _assertFilesWithoutLibraryCycle([]);

    // It's a cycle.
    _assertLibraryCycle(fa, [fa, fb], []);
    _assertLibraryCycle(fb, [fa, fb], []);
    expect(fa.libraryCycle, same(fb.libraryCycle));

    // Update a.dart so that it does not import b.dart anymore.
    newFile(pa, '');
    fa.refresh();
    _assertFilesWithoutLibraryCycle([fa, fb]);
    _assertLibraryCycle(fa, [fa], []);
    _assertLibraryCycle(fb, [fb], [fa.libraryCycle]);
  }

  test_libraryCycle_invalidPart_withPart() {
    var pa = convertPath('/aaa/lib/a.dart');

    newFile(pa, r'''
part of lib;
part 'a.dart';
''');

    var fa = fileSystemState.getFileForPath(pa);

    _assertLibraryCycle(fa, [fa], []);
  }

  test_libraryCycle_part() {
    var a_path = convertPath('/aaa/lib/a.dart');
    var b_path = convertPath('/aaa/lib/b.dart');

    newFile(a_path, r'''
part 'b.dart';
''');
    newFile(b_path, r'''
part of 'a.dart';
''');

    var a_file = fileSystemState.getFileForPath(a_path);
    var b_file = fileSystemState.getFileForPath(b_path);
    _assertFilesWithoutLibraryCycle([a_file, b_file]);

    // Compute the library cycle for 'a.dart', the library.
    var a_libraryCycle = a_file.libraryCycle;
    _assertFilesWithoutLibraryCycle([b_file]);

    // The part 'b.dart' has its own library cycle.
    // If the user chooses to import a part, it is a compile-time error.
    // We could handle this in different ways:
    // 1. Completely ignore an import of a file with a `part of` directive.
    // 2. Treat such file as a library anyway.
    // By giving a part its own library cycle we support (2).
    var b_libraryCycle = b_file.libraryCycle;
    expect(b_libraryCycle, isNot(same(a_libraryCycle)));
    _assertFilesWithoutLibraryCycle([]);
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
    final changeKind = file.refresh();
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
    final changeKind = file.refresh();
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

  test_transitiveSignature() {
    String pa = convertPath('/aaa/lib/a.dart');
    String pb = convertPath('/aaa/lib/b.dart');
    String pc = convertPath('/aaa/lib/c.dart');
    String pd = convertPath('/aaa/lib/d.dart');

    newFile(pa, "class A {}");
    newFile(pb, "import 'a.dart';");
    newFile(pc, "import 'b.dart';");
    newFile(pd, "class D {}");

    FileState fa = fileSystemState.getFileForPath(pa);
    FileState fb = fileSystemState.getFileForPath(pb);
    FileState fc = fileSystemState.getFileForPath(pc);
    FileState fd = fileSystemState.getFileForPath(pd);

    // Compute transitive closures for all files.
    // This implicitly computes library cycles.
    expect(fa.transitiveSignature, isNotNull);
    expect(fb.transitiveSignature, isNotNull);
    expect(fc.transitiveSignature, isNotNull);
    expect(fd.transitiveSignature, isNotNull);
    _assertFilesWithoutLibraryCycle([]);

    // Make an update to a.dart that does not change its API signature.
    // All library cycles are still valid.
    newFile(pa, "class A {} // the same API signature");
    fa.refresh();
    _assertFilesWithoutLibraryCycle([]);

    // Change a.dart API signature.
    // This flushes signatures of b.dart and c.dart, but d.dart is still OK.
    newFile(pa, "class A2 {}");
    fa.refresh();
    _assertFilesWithoutLibraryCycle([fa, fb, fc]);
  }

  test_transitiveSignature_part() {
    var aPath = convertPath('/test/lib/a.dart');
    var bPath = convertPath('/test/lib/b.dart');

    newFile(aPath, r'''
part 'b.dart';
''');
    newFile(bPath, '''
part of 'a.dart';
''');

    var aFile = fileSystemState.getFileForPath(aPath);
    var bFile = fileSystemState.getFileForPath(bPath);

    var aSignature = aFile.transitiveSignature;
    var bSignature = bFile.transitiveSignature;

    // It is not valid to use a part as a library, and so ask its signature.
    // But when this happens, we should compute the transitive signature anyway.
    // And it should not be the signature of the containing library.
    expect(bSignature, isNot(aSignature));
  }

  void _assertFilesWithoutLibraryCycle(List<FileState> expected) {
    var actual = fileSystemState.test.filesWithoutLibraryCycle;
    expect(_excludeSdk(actual), unorderedEquals(expected));
  }

  void _assertIsUnresolvedFile(FileState? file) {
    expect(file, isNull);
  }

  void _assertLibraryCycle(
    FileState file,
    List<FileState> expectedLibraries,
    List<LibraryCycle> expectedDirectDependencies,
  ) {
    expect(file.libraryCycle.libraries, unorderedEquals(expectedLibraries));
    expect(
      _excludeSdk(file.libraryCycle.directDependencies),
      unorderedEquals(expectedDirectDependencies),
    );
  }

  List<T> _excludeSdk<T>(Iterable<T> files) {
    return files.where((file) {
      if (file is LibraryCycle) {
        return !file.libraries.any((file) => file.uri.isScheme('dart'));
      } else if (file is FileState) {
        return !file.uri.isScheme('dart');
      } else if (file == null) {
        return true;
      } else {
        return !(file as String).startsWith(convertPath('/sdk'));
      }
    }).toList();
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

extension _Either2Extension<T1, T2> on Either2<T1, T2> {
  T1 get t1 {
    late T1 result;
    map(
      (t1) => result = t1,
      (_) => throw 'Expected T1',
    );
    return result;
  }
}
