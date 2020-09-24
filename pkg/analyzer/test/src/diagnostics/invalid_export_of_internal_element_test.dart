// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/mock_packages.dart';
import 'package:analyzer/src/workspace/bazel.dart';
import 'package:analyzer/src/workspace/package_build.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidExportOfInternalElement_BazelPackageTest);
    defineReflectiveTests(
        InvalidExportOfInternalElement_PackageBuildPackageTest);
    defineReflectiveTests(InvalidExportOfInternalElement_PubPackageTest);
  });
}

@reflectiveTest
class InvalidExportOfInternalElement_BazelPackageTest
    extends BazelWorkspaceResolutionTest
    with InvalidExportOfInternalElementTest {
  /// A cached analysis context for resolving sources via the same [Workspace].
  AnalysisContext analysisContext;

  String get testPackageBazelBinPath => '$workspaceRootPath/bazel-bin/dart/my';

  String get testPackageGenfilesPath =>
      '$workspaceRootPath/bazel-genfiles/dart/my';

  @override
  String get testPackageLibPath => myPackageLibPath;

  @override
  Future<ResolvedUnitResult> resolveFile(String path) {
    analysisContext ??= contextFor(path);
    assert(analysisContext.workspace is BazelWorkspace);
    return analysisContext.currentSession.getResolvedUnit(path);
  }

  @override
  void setUp() async {
    super.setUp();
    var metaPath = '$workspaceThirdPartyDartPath/meta';
    MockPackages.addMetaPackageFiles(
      getFolder(metaPath),
    );
    newFile('$testPackageBazelBinPath/my.packages');
    newFolder('$workspaceRootPath/bazel-out');
  }

  void test_exporterIsInBazelBinLib() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');
    await resolveFile2(testPackageImplementationFilePath);

    newFile('$testPackageBazelBinPath/lib/bar.dart', content: r'''
export 'src/foo.dart';
''');
    await resolveFile2('$testPackageBazelBinPath/lib/bar.dart');

    assertErrorsInResolvedUnit(result, [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 22),
    ]);
  }

  void test_exporterIsInBazelBinLibSrc() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');
    await resolveFile2(testPackageImplementationFilePath);

    newFile('$testPackageBazelBinPath/lib/src/bar.dart', content: r'''
export 'foo.dart';
''');
    await resolveFile2('$testPackageBazelBinPath/lib/src/bar.dart');

    assertErrorsInResolvedUnit(result, []);
  }

  void test_exporterIsInGenfilesLib() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');
    await resolveFile2(testPackageImplementationFilePath);

    newFile('$testPackageGenfilesPath/lib/bar.dart', content: r'''
export 'src/foo.dart';
''');
    await resolveFile2('$testPackageGenfilesPath/lib/bar.dart');

    assertErrorsInResolvedUnit(result, [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 22),
    ]);
  }

  void test_exporterIsInGenfilesLibSrc() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');
    await resolveFile2(testPackageImplementationFilePath);

    newFile('$testPackageGenfilesPath/lib/src/bar.dart', content: r'''
export 'foo.dart';
''');
    await resolveFile2('$testPackageGenfilesPath/lib/src/bar.dart');

    assertErrorsInResolvedUnit(result, []);
  }

  void test_exporterIsInLib() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    newFile('$testPackageLibPath/bar.dart', content: r'''
export 'src/foo.dart';
''');
    await resolveFile2('$testPackageLibPath/bar.dart');

    assertErrorsInResolvedUnit(result, [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 22),
    ]);
  }

  void test_exporterIsInLibSrc() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    newFile('$testPackageLibPath/src/bar.dart', content: r'''
export 'foo.dart';
''');
    await resolveFile2('$testPackageLibPath/src/bar.dart');

    assertErrorsInResolvedUnit(result, []);
  }

  void test_exporterIsInTest() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    newFile('$myPackageRootPath/test/foo_test.dart', content: r'''
export 'package:dart.my/src/foo.dart';
''');
    await resolveFile2('$myPackageRootPath/test/foo_test.dart');

    assertErrorsInResolvedUnit(result, []);
  }

  void test_internalIsInBazelBin() async {
    newFile('$testPackageBazelBinPath/lib/src/foo.dart', content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await assertErrorsInCode(r'''
export 'package:dart.my/src/foo.dart';
''', [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 38),
    ]);
  }

  void test_internalIsInGenfiles() async {
    newFile('$testPackageGenfilesPath/lib/src/foo.dart', content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await assertErrorsInCode(r'''
export 'package:dart.my/src/foo.dart';
''', [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 38),
    ]);
  }

  void test_internalIsInLibSrc() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await assertErrorsInCode(r'''
export 'package:dart.my/src/foo.dart';
''', [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 38),
    ]);
  }
}

@reflectiveTest
class InvalidExportOfInternalElement_PackageBuildPackageTest
    extends InvalidExportOfInternalElement_PubPackageTest {
  /// A cached analysis context for resolving sources via the same [Workspace].
  AnalysisContext analysisContext;

  String get testPackageDartToolPath =>
      '$testPackageRootPath/.dart_tool/build/generated/test';

  @override
  Future<ResolvedUnitResult> resolveFile(String path) {
    analysisContext ??= contextFor(path);
    assert(analysisContext.workspace is PackageBuildWorkspace);
    return analysisContext.currentSession.getResolvedUnit(path);
  }

  @override
  void setUp() async {
    analysisContext = null;
    super.setUp();
    newFolder(testPackageDartToolPath);
  }

  void test_exporterInGeneratedLib() async {
    newFile('$testPackageRootPath/lib/src/foo.dart', content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');
    await resolveFile2('$testPackageRootPath/lib/src/foo.dart');

    newFile('$testPackageDartToolPath/lib/bar.dart', content: r'''
export 'package:test/src/foo.dart';
''');
    await resolveFile2('$testPackageDartToolPath/lib/bar.dart');

    assertErrorsInResolvedUnit(result, [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 35),
    ]);
  }

  void test_exporterInGeneratedLibSrc() async {
    newFile('$testPackageRootPath/lib/src/foo.dart', content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');
    await resolveFile2('$testPackageRootPath/lib/src/foo.dart');

    newFile('$testPackageDartToolPath/lib/src/bar.dart', content: r'''
export 'package:test/src/foo.dart';
''');
    await resolveFile2('$testPackageDartToolPath/lib/src/bar.dart');

    assertErrorsInResolvedUnit(result, []);
  }

  void test_exporterInLib() async {
    newFile('$testPackageRootPath/lib/src/foo.dart', content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');
    await resolveFile2('$testPackageRootPath/lib/src/foo.dart');

    newFile('$testPackageRootPath/lib/bar.dart', content: r'''
export 'package:test/src/foo.dart';
''');
    await resolveFile2('$testPackageRootPath/lib/bar.dart');

    assertErrorsInResolvedUnit(result, [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 35),
    ]);
  }

  void test_exporterInLibSrc() async {
    newFile('$testPackageRootPath/lib/src/foo.dart', content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');
    await resolveFile2('$testPackageRootPath/lib/src/foo.dart');

    newFile('$testPackageRootPath/lib/src/bar.dart', content: r'''
export 'package:test/src/foo.dart';
''');
    await resolveFile2('$testPackageRootPath/lib/src/bar.dart');

    assertErrorsInResolvedUnit(result, []);
  }

  void test_internalIsInGeneratedLibSrc() async {
    newFile('$testPackageDartToolPath/lib/src/foo.dart', content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await assertErrorsInCode(r'''
export 'package:test/src/foo.dart';
''', [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 35),
    ]);
  }

  @override
  void test_internalIsLibSrc() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await assertErrorsInCode(r'''
export 'package:test/src/foo.dart';
''', [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 35),
    ]);
  }
}

@reflectiveTest
class InvalidExportOfInternalElement_PubPackageTest
    extends PubPackageResolutionTest with InvalidExportOfInternalElementTest {
  @override
  void setUp() async {
    super.setUp();
    writeTestPackageConfigWithMeta();
    newFile('$testPackageRootPath/pubspec.yaml', content: r'''
name: test
version: 0.0.1
''');
  }

  void test_exporterIsInLib() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    newFile('$testPackageLibPath/bar.dart', content: r'''
export 'src/foo.dart';
''');
    await resolveFile2('$testPackageLibPath/bar.dart');

    assertErrorsInResolvedUnit(result, [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 22),
    ]);
  }

  void test_exporterIsInLibSrc() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    newFile('$testPackageLibPath/src/bar.dart', content: r'''
export 'foo.dart';
''');
    await resolveFile2('$testPackageLibPath/src/bar.dart');

    assertErrorsInResolvedUnit(result, []);
  }

  void test_exporterIsInTest() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    newFile('$testPackageRootPath/test/foo_test.dart', content: r'''
export 'package:test/src/foo.dart';
''');
    await resolveFile2('$testPackageRootPath/test/foo_test.dart');

    assertErrorsInResolvedUnit(result, []);
  }

  void test_internalIsLibSrc() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await assertErrorsInCode(r'''
export 'package:test/src/foo.dart';
''', [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 35),
    ]);
  }
}

mixin InvalidExportOfInternalElementTest on ContextResolutionTest {
  String get testPackageImplementationFilePath =>
      '$testPackageLibPath/src/foo.dart';

  String get testPackageLibPath;

  void test_hideCombinator_internalHidden() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
class Two {}
''');

    await assertNoErrorsInCode(r'''
export 'src/foo.dart' hide One;
''');
  }

  void test_hideCombinator_internalNotHidden() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
class Two {}
''');

    await assertErrorsInCode(r'''
export 'src/foo.dart' hide Two;
''', [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 31),
    ]);
  }

  void test_noCombinators() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await assertErrorsInCode(r'''
export 'src/foo.dart';
''', [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 22),
    ]);
  }

  void test_noCombinators_indirectExport() async {
    newFile(testPackageImplementationFilePath, content: r'''
export 'bar.dart';
''');

    newFile('$testPackageLibPath/src/bar.dart', content: r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await assertErrorsInCode(r'''
export 'src/foo.dart';
''', [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 22),
    ]);
  }

  void test_noCombinators_library() async {
    newFile(testPackageImplementationFilePath, content: r'''
@internal
library foo;

import 'package:meta/meta.dart';
''');

    await assertErrorsInCode(r'''
export 'src/foo.dart';
''', [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 22),
    ]);
  }

  void test_noCombinators_library_notInternal() async {
    newFile(testPackageImplementationFilePath, content: r'''
library foo;
''');

    await assertNoErrorsInCode(r'''
export 'src/foo.dart';
''');
  }

  void test_noCombinators_noInternal() async {
    newFile(testPackageImplementationFilePath, content: r'''
class One {}
''');

    await assertNoErrorsInCode(r'''
export 'src/foo.dart';
''');
  }

  void test_showCombinator_internalNotShown() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
class Two {}
''');

    await assertNoErrorsInCode(r'''
export 'src/foo.dart' show Two;
''');
  }

  void test_showCombinator_internalShown() async {
    newFile(testPackageImplementationFilePath, content: r'''
import 'package:meta/meta.dart';
@internal class One {}
class Two {}
''');

    await assertErrorsInCode(r'''
export 'src/foo.dart' show One;
''', [
      error(HintCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT, 0, 31),
    ]);
  }
}
