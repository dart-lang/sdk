// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
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
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FileSystemStateTest);
    defineReflectiveTests(FileSystemState_BazelWorkspaceTest);
    defineReflectiveTests(FileSystemState_PubPackageTest);
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
  FileState fileStateFor(File file) {
    return fsStateFor(file).getFileForPath(file.path);
  }

  FileSystemState fsStateFor(File file) {
    return driverFor(file.path).fsState;
  }

  test_newFile_library_includePart_withoutPartOf() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
// no part of
''');

    final aState = fileStateFor(a);
    aState.assertKind((kind) {
      kind as LibraryFileStateKind;
    });

    // Library `a.dart` includes `b.dart` as a part.
    _assertPartedFiles(aState, [b]);

    // But `b.dart` thinks that it is a library itself.
    final bState = fileStateFor(b);
    bState.assertKind((kind) {
      kind as LibraryFileStateKind;
    });

    // Refreshing the library does not change this.
    aState.refresh();
    _assertPartedFiles(aState, [b]);
    bState.assertKind((kind) {
      kind as LibraryFileStateKind;
    });
  }

  test_newFile_libraryAugmentation_invalid() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library augment 'da:';
''');

    final aState = fileStateFor(a);
    aState.assertKind((kind) {
      kind as LibraryAugmentationUnknownFileStateKind;
    });
  }

  /// TODO(scheglov) implement
  @FailingTest(reason: 'No import augment directive')
  test_newFile_libraryAugmentation_valid() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    final b = newFile('$testPackageLibPath/a.dart', r'''
library augment 'a.dart';
''');

    final bState = fileStateFor(b);
    bState.assertKind((kind) {
      kind as LibraryAugmentationKnownFileStateKind;
      final aState = fileStateFor(a);
      expect(kind.augmented, same(aState));
    });
  }

  test_newFile_libraryDirective() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library my;
''');

    final aState = fileStateFor(a);
    aState.assertKind((kind) {
      kind as LibraryFileStateKind;
    });
  }

  test_newFile_noDirectives() async {
    final a = newFile('$testPackageLibPath/a.dart', '');

    final aState = fileStateFor(a);
    aState.assertKind((kind) {
      kind as LibraryFileStateKind;
    });
  }

  test_newFile_partOfName() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library my.lib;
part 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of my.lib;
''');

    final bState = fileStateFor(b);

    // We don't know the library initially.
    // Even though the library file exists, we have not seen it yet.
    bState.assertKind((kind) {
      kind as PartUnknownNameFileStateKind;
      expect(kind.directive.name, 'my.lib');
    });

    // Read the library file.
    final aState = fileStateFor(a);
    aState.assertKind((kind) {
      kind as LibraryFileStateKind;
    });
    _assertPartedFiles(aState, [b]);

    // Now the part knows its library.
    bState.assertKind((kind) {
      kind as PartKnownFileStateKind;
      expect(kind.library, same(aState));
    });
  }

  test_newFile_partOfName_differentName() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
library my.lib;
part 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of other.lib;
''');

    final bState = fileStateFor(b);

    // We don't know the library initially.
    // Even though the library file exists, we have not seen it yet.
    bState.assertKind((kind) {
      kind as PartUnknownNameFileStateKind;
      expect(kind.directive.name, 'other.lib');
    });

    // Read the library file.
    final aState = fileStateFor(a);
    aState.assertKind((kind) {
      kind as LibraryFileStateKind;
    });
    _assertPartedFiles(aState, [b]);

    // Now the part knows its library.
    // The name of the library in the part file does not matter.
    // What counts is that the library includes it.
    bState.assertKind((kind) {
      kind as PartKnownFileStateKind;
      expect(kind.library, same(aState));
    });
  }

  test_newFile_partOfName_twoLibraries() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part 'c.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part 'c.dart';
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
part of 'doesNotMatter.dart';
''');

    final aState = fileStateFor(a);
    _assertPartedFiles(aState, [c]);

    // We set the library while reading `a.dart` file.
    final cState = fileStateFor(c);
    cState.assertKind((kind) {
      kind as PartKnownFileStateKind;
      expect(kind.library, aState);
    });

    // Reading `b.dart` does not update the part.
    final bState = fileStateFor(b);
    _assertPartedFiles(bState, [c]);
    cState.assertKind((kind) {
      kind as PartKnownFileStateKind;
      expect(kind.library, aState);
    });

    // Refreshing `b.dart` does not update the part.
    bState.refresh();
    cState.assertKind((kind) {
      kind as PartKnownFileStateKind;
      expect(kind.library, aState);
    });

    // Exclude the part from `a.dart` - switches to `b.dart` as its library.
    newFile(a.path, '');
    aState.refresh();
    cState.assertKind((kind) {
      kind as PartKnownFileStateKind;
      expect(kind.library, bState);
    });

    // Exclude the part from `b.dart` as well - switches to unknown.
    newFile(b.path, '');
    bState.refresh();
    cState.assertKind((kind) {
      kind as PartUnknownUriFileStateKind;
    });
  }

  test_newFile_partOfUri_doesNotExist() async {
    final b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    final bState = fileStateFor(b);

    // If the library does not part the file, it does not matter what the
    // part file says - the part file will not be analyzed during the library
    // analysis.
    bState.assertKind((kind) {
      kind as PartUnknownUriFileStateKind;
    });

    // Create the library that includes the part file.
    final a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    // The library file has already been read because of `part of uri`.
    // So, we explicitly refresh it.
    final aState = fileStateFor(a);
    aState.refresh();
    _assertPartedFiles(aState, [b]);

    // Now the part file knows its library.
    bState.assertKind((kind) {
      kind as PartKnownFileStateKind;
      expect(kind.library, same(aState));
    });

    // Refreshing the part file does not break the kind.
    bState.refresh();
    bState.assertKind((kind) {
      kind as PartKnownFileStateKind;
      expect(kind.library, same(aState));
    });
  }

  test_newFile_partOfUri_exists_hasPart() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    final bState = fileStateFor(b);
    bState.assertKind((kind) {
      kind as PartKnownFileStateKind;
      // We have not read the library file explicitly yet.
      // But it was read because of the `part of` directive.
      final aState = fileStateFor(a);
      _assertPartedFiles(aState, [b]);
      expect(kind.library, same(aState));
    });

    // Refreshing the part file does not break the kind.
    bState.refresh();
    bState.assertKind((kind) {
      kind as PartKnownFileStateKind;
      final aState = fileStateFor(a);
      expect(kind.library, same(aState));
    });
  }

  test_newFile_partOfUri_exists_noPart() async {
    newFile('$testPackageLibPath/a.dart', '');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    final bState = fileStateFor(b);

    // If the library does not part the file, it does not matter what the
    // part file says - the part file will not be analyzed during the library
    // analysis.
    bState.assertKind((kind) {
      kind as PartUnknownUriFileStateKind;
    });
  }

  test_newFile_partOfUri_invalid() async {
    final b = newFile('$testPackageLibPath/b.dart', r'''
part of 'da:';
''');

    final bState = fileStateFor(b);

    // The URI is invalid, so there is no way to discover the library.
    bState.assertKind((kind) {
      kind as PartUnknownUriFileStateKind;
      expect(kind.directive.uri, 'da:');
    });

    // But reading a library that includes this part will update it.
    final a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');
    final aState = fileStateFor(a);
    _assertPartedFiles(aState, [b]);

    bState.assertKind((kind) {
      kind as PartKnownFileStateKind;
      expect(kind.library, same(aState));
    });
  }

  test_refresh_library_removePart_partOfName() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part of my;
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of my;
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
library my;
part 'a.dart';
part 'b.dart';
''');

    final cState = fileStateFor(c);
    cState.assertKind((kind) {
      kind as LibraryFileStateKind;
    });
    _assertPartedFiles(cState, [a, b]);

    final aState = fileStateFor(a);
    final bState = fileStateFor(b);

    // Both part files know the library.
    aState.assertKind((kind) {
      kind as PartKnownFileStateKind;
      expect(kind.library, cState);
    });
    bState.assertKind((kind) {
      kind as PartKnownFileStateKind;
      expect(kind.library, cState);
    });

    newFile(c.path, r'''
library my;
part 'b.dart';
''');

    // Stop referencing `a.dart` part file.
    cState.refresh();
    _assertPartedFiles(cState, [b]);

    // So, the `a.dart` does not know its library anymore.
    // But `b.dart` still knows it.
    aState.assertKind((kind) {
      kind as PartUnknownNameFileStateKind;
    });
    bState.assertKind((kind) {
      kind as PartKnownFileStateKind;
      expect(kind.library, cState);
    });
  }

  test_refresh_library_removePart_partOfUri() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
''');

    final c = newFile('$testPackageLibPath/c.dart', r'''
library my;
part 'a.dart';
part 'b.dart';
''');

    final cState = fileStateFor(c);
    cState.assertKind((kind) {
      kind as LibraryFileStateKind;
    });
    _assertPartedFiles(cState, [a, b]);

    final aState = fileStateFor(a);
    final bState = fileStateFor(b);

    // Both part files know the library.
    aState.assertKind((kind) {
      kind as PartKnownFileStateKind;
      expect(kind.library, cState);
    });
    bState.assertKind((kind) {
      kind as PartKnownFileStateKind;
      expect(kind.library, cState);
    });

    newFile(c.path, r'''
library my;
part 'b.dart';
''');

    // Stop referencing `a.dart` part file.
    cState.refresh();
    _assertPartedFiles(cState, [b]);

    // So, the `a.dart` does not know its library anymore.
    // But `b.dart` still knows it.
    aState.assertKind((kind) {
      kind as PartUnknownUriFileStateKind;
    });
    bState.assertKind((kind) {
      kind as PartKnownFileStateKind;
      expect(kind.library, cState);
    });
  }

  test_refresh_library_to_partOfName() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    // No `part of`, so it is a library.
    final b = newFile('$testPackageLibPath/b.dart', '');

    final aState = fileStateFor(a);
    _assertPartedFiles(aState, [b]);

    final aCycle_1 = aState.libraryCycle;

    // No `part of`, so it is a library.
    // It does not matter, that `a.dart` tried to use it as part.
    final bState = fileStateFor(b);
    bState.assertKind((kind) {
      kind as LibraryFileStateKind;
    });

    // Make it a part.
    newFile(b.path, r'''
part of my.lib;
''');

    // We will discover the library, by asking each of them.
    bState.refresh();
    bState.assertKind((kind) {
      kind as PartKnownFileStateKind;
      expect(kind.library, same(aState));
    });

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
    aState.assertKind((kind) {
      kind as LibraryFileStateKind;
    });

    newFile(a.path, r'''
part of my;
''');

    aState.refresh();

    // No library that includes it, so it stays unknown.
    aState.assertKind((kind) {
      kind as PartUnknownNameFileStateKind;
      expect(kind.directive.name, 'my');
    });
  }

  test_refresh_library_to_partOfUri() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library b;
''');

    final aState = fileStateFor(a);
    _assertPartedFiles(aState, [b]);

    final aCycle_1 = aState.libraryCycle;

    final bState = fileStateFor(b);
    bState.assertKind((kind) {
      kind as LibraryFileStateKind;
    });

    newFile(b.path, r'''
part of 'a.dart';
''');

    // We will discover the library, by asking each of them.
    bState.refresh();
    bState.assertKind((kind) {
      kind as PartKnownFileStateKind;
      expect(kind.library, same(aState));
    });

    // The file `b.dart` was something else, but now it is a known part.
    // This affects libraries that include it.
    final aCycle_2 = aState.libraryCycle;
    expect(aCycle_2.apiSignature, isNot(aCycle_1.apiSignature));
  }

  test_refresh_partOfUri_to_library() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
''');

    final aState = fileStateFor(a);
    aState.assertKind((kind) {
      kind as LibraryFileStateKind;
    });
    _assertPartedFiles(aState, [b]);

    final aCycle_1 = aState.libraryCycle;

    // There is `part of` in `b.dart`, so it is a part.
    final bState = fileStateFor(b);
    bState.assertKind((kind) {
      kind as PartKnownFileStateKind;
      expect(kind.library, aState);
    });

    // There are no directives in `b.dart`, so it is a library.
    newFile(b.path, r'''
// no part of
''');
    bState.refresh();
    bState.assertKind((kind) {
      kind as LibraryFileStateKind;
    });

    // Library `a.dart` still considers `b.dart` its part.
    _assertPartedFiles(aState, [b]);

    // The library cycle for `a.dart` is different now.
    final aCycle_2 = aState.libraryCycle;
    expect(aCycle_2.apiSignature, isNot(aCycle_1.apiSignature));
  }

  void _assertPartedFiles(FileState fileState, List<File> expected) {
    final actualFiles = fileState.partedFiles.map((part) {
      if (part != null) {
        return getFile(part.path);
      }
    }).toList();
    expect(actualFiles, expected);
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
      fileContentCache: FileContentCache.ephemeral(resourceProvider),
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

  test_getFileForPath_doesNotExist() {
    String path = convertPath('/aaa/lib/a.dart');
    FileState file = fileSystemState.getFileForPath(path);
    expect(file.path, path);
    expect(file.uri, Uri.parse('package:aaa/a.dart'));
    expect(file.content, '');
    expect(file.contentHash, _md5(''));
    expect(_excludeSdk(file.importedFiles), isEmpty);
    expect(file.exportedFiles, isEmpty);
    expect(file.partedFiles, isEmpty);
    expect(file.libraryFiles, [file]);
    expect(_excludeSdk(file.directReferencedFiles), isEmpty);
    expect(file.isPart, isFalse);
    expect(file.library, isNull);
    expect(file.unlinked2, isNotNull);
    expect(file.unlinked2.exports, isEmpty);
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

  test_getFileForPath_library() {
    String a1 = convertPath('/aaa/lib/a1.dart');
    String a2 = convertPath('/aaa/lib/a2.dart');
    String a3 = convertPath('/aaa/lib/a3.dart');
    String a4 = convertPath('/aaa/lib/a4.dart');
    String b1 = convertPath('/bbb/lib/b1.dart');
    String b2 = convertPath('/bbb/lib/b2.dart');
    String content_a1 = r'''
import 'package:aaa/a2.dart';
import 'package:bbb/b1.dart';
export 'package:bbb/b2.dart';
export 'package:aaa/a3.dart';
part 'a4.dart';

class A1 {}
''';
    newFile(a1, content_a1);

    FileState file = fileSystemState.getFileForPath(a1);
    expect(file.path, a1);
    expect(file.content, content_a1);
    expect(file.contentHash, _md5(content_a1));

    expect(file.isPart, isFalse);
    expect(file.library, isNull);
    expect(file.unlinked2, isNotNull);

    expect(_excludeSdk(file.importedFiles), hasLength(2));
    expect(file.importedFiles[0]!.path, a2);
    expect(file.importedFiles[0]!.uri, Uri.parse('package:aaa/a2.dart'));
    expect(file.importedFiles[0]!.source, isNotNull);
    expect(file.importedFiles[1]!.path, b1);
    expect(file.importedFiles[1]!.uri, Uri.parse('package:bbb/b1.dart'));
    expect(file.importedFiles[1]!.source, isNotNull);

    expect(file.exportedFiles, hasLength(2));
    expect(file.exportedFiles[0]!.path, b2);
    expect(file.exportedFiles[0]!.uri, Uri.parse('package:bbb/b2.dart'));
    expect(file.exportedFiles[0]!.source, isNotNull);
    expect(file.exportedFiles[1]!.path, a3);
    expect(file.exportedFiles[1]!.uri, Uri.parse('package:aaa/a3.dart'));
    expect(file.exportedFiles[1]!.source, isNotNull);

    expect(file.partedFiles, hasLength(1));
    expect(file.partedFiles[0]!.path, a4);
    expect(file.partedFiles[0]!.uri, Uri.parse('package:aaa/a4.dart'));

    expect(file.libraryFiles, [file, file.partedFiles[0]]);

    expect(_excludeSdk(file.directReferencedFiles), hasLength(5));
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

  test_getFileForPath_part() {
    String a1 = convertPath('/aaa/lib/a1.dart');
    String a2 = convertPath('/aaa/lib/a2.dart');
    newFile(a1, r'''
library a1;
part 'a2.dart';
''');
    newFile(a2, r'''
part of a1;
class A2 {}
''');

    FileState file_a2 = fileSystemState.getFileForPath(a2);
    expect(file_a2.path, a2);
    expect(file_a2.uri, Uri.parse('package:aaa/a2.dart'));

    expect(file_a2.unlinked2, isNotNull);

    expect(_excludeSdk(file_a2.importedFiles), isEmpty);
    expect(file_a2.exportedFiles, isEmpty);
    expect(file_a2.partedFiles, isEmpty);
    expect(_excludeSdk(file_a2.directReferencedFiles), isEmpty);

    // The library is not known yet.
    expect(file_a2.isPart, isTrue);
    expect(file_a2.library, isNull);

    // Ask for the library.
    FileState file_a1 = fileSystemState.getFileForPath(a1);
    expect(file_a1.partedFiles, hasLength(1));
    expect(file_a1.partedFiles[0], same(file_a2));
    expect(
        _excludeSdk(file_a1.directReferencedFiles), unorderedEquals([file_a2]));

    // Now the part knows its library.
    expect(file_a2.library, same(file_a1));

    // Now update the library, and refresh its file.
    // The 'a2.dart' is not referenced anymore.
    // So the part file does not have the library anymore.
    newFile(a1, r'''
library a1;
part 'not-a2.dart';
''');
    file_a1.refresh();
    expect(file_a2.library, isNull);
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
    byteStore.put(file.test.unlinkedKey, Uint8List(0));

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

  static String _md5(String content) {
    return hex.encode(md5.convert(utf8.encode(content)).bytes);
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

extension on FileState {
  void assertKind(void Function(FileStateKind kind) f) {
    expect(kind.file, same(this));
    f(kind);
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
