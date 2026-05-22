// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_testing/mock_packages/mock_packages.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidExportOfInternalElement_BlazePackageTest);
    defineReflectiveTests(
      InvalidExportOfInternalElement_PackageBuildPackageTest,
    );
    defineReflectiveTests(InvalidExportOfInternalElement_PubPackageTest);
  });
}

@reflectiveTest
class InvalidExportOfInternalElement_BlazePackageTest
    extends BlazeWorkspaceResolutionTest
    with InvalidExportOfInternalElementTest, MockPackagesMixin {
  @override
  String get packagesRootPath => workspaceThirdPartyDartPath;

  String get testPackageBlazeBinPath => '$workspaceRootPath/blaze-bin/dart/my';

  String get testPackageGenfilesPath =>
      '$workspaceRootPath/blaze-genfiles/dart/my';

  @override
  String get testPackageLibPath => myPackageLibPath;

  @override
  void setUp() {
    super.setUp();
    addMeta();
    newFile('$testPackageBlazeBinPath/my.packages', '');
    newFolder('$workspaceRootPath/blaze-out');
  }

  void test_exporterIsInBlazeBinLib() async {
    newFile(testPackageImplementationFilePath, r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    var result = await resolveFileCode(
      '$testPackageBlazeBinPath/lib/bar.dart',
      r'''
export 'src/foo.dart';
''',
    );

    assertErrorsInTestResult(result, [
      error(diag.invalidExportOfInternalElement, 0, 22),
    ]);
  }

  void test_exporterIsInBlazeBinLibSrc() async {
    newFile(testPackageImplementationFilePath, r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    var result = await resolveFileCode(
      '$testPackageBlazeBinPath/lib/src/bar.dart',
      r'''
export 'foo.dart';
''',
    );

    assertNoErrorsInTestResult(result);
  }

  void test_exporterIsInGenfilesLib() async {
    newFile(testPackageImplementationFilePath, r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    var result = await resolveFileCode(
      '$testPackageGenfilesPath/lib/bar.dart',
      r'''
export 'src/foo.dart';
''',
    );

    assertErrorsInTestResult(result, [
      error(diag.invalidExportOfInternalElement, 0, 22),
    ]);
  }

  void test_exporterIsInGenfilesLibSrc() async {
    newFile(testPackageImplementationFilePath, r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    var result = await resolveFileCode(
      '$testPackageGenfilesPath/lib/src/bar.dart',
      r'''
export 'foo.dart';
''',
    );

    assertNoErrorsInTestResult(result);
  }

  void test_exporterIsInLib() async {
    newFile(testPackageImplementationFilePath, r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    var result = await resolveFileCode('$testPackageLibPath/bar.dart', r'''
export 'src/foo.dart';
''');

    assertErrorsInTestResult(result, [
      error(diag.invalidExportOfInternalElement, 0, 22),
    ]);
  }

  void test_exporterIsInLibSrc() async {
    newFile(testPackageImplementationFilePath, r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    var result = await resolveFileCode('$testPackageLibPath/src/bar.dart', r'''
export 'foo.dart';
''');

    assertNoErrorsInTestResult(result);
  }

  void test_exporterIsInTest() async {
    newFile(testPackageImplementationFilePath, r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    var result = await resolveFileCode(
      '$myPackageRootPath/test/foo_test.dart',
      r'''
export 'package:dart.my/src/foo.dart';
''',
    );

    assertNoErrorsInTestResult(result);
  }

  void test_internalIsInBlazeBin() async {
    newFile('$testPackageBlazeBinPath/lib/src/foo.dart', r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'package:dart.my/src/foo.dart';
// [diag.invalidExportOfInternalElement][column 1][length 38] The member 'One' can't be exported as a part of a package's public API.
''');
  }

  void test_internalIsInGenfiles() async {
    newFile('$testPackageGenfilesPath/lib/src/foo.dart', r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'package:dart.my/src/foo.dart';
// [diag.invalidExportOfInternalElement][column 1][length 38] The member 'One' can't be exported as a part of a package's public API.
''');
  }

  void test_internalIsInLibSrc() async {
    newFile(testPackageImplementationFilePath, r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'package:dart.my/src/foo.dart';
// [diag.invalidExportOfInternalElement][column 1][length 38] The member 'One' can't be exported as a part of a package's public API.
''');
  }
}

@reflectiveTest
class InvalidExportOfInternalElement_PackageBuildPackageTest
    extends InvalidExportOfInternalElement_PubPackageTest {
  String get testPackageDartToolPath =>
      '$testPackageRootPath/.dart_tool/build/generated/test';

  @FailingTest(
    reason: r'''
We try to analyze a file in .dart_tool, which is implicitly excluded from
analysis. So, there is no context to analyze it.
''',
  )
  void test_exporterInGeneratedLib() async {
    newFile('$testPackageRootPath/lib/src/foo.dart', r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    var result = await resolveFileCode(
      '$testPackageDartToolPath/lib/bar.dart',
      r'''
export 'package:test/src/foo.dart';
''',
    );

    assertErrorsInTestResult(result, [
      error(diag.invalidExportOfInternalElement, 0, 35),
    ]);
  }

  @FailingTest(
    reason: r'''
We try to analyze a file in .dart_tool, which is implicitly excluded from
analysis. So, there is no context to analyze it.
''',
  )
  void test_exporterInGeneratedLibSrc() async {
    newFile('$testPackageRootPath/lib/src/foo.dart', r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    var result = await resolveFileCode(
      '$testPackageDartToolPath/lib/src/bar.dart',
      r'''
export 'package:test/src/foo.dart';
''',
    );

    assertNoErrorsInTestResult(result);
  }

  void test_exporterInLib() async {
    newFile('$testPackageRootPath/lib/src/foo.dart', r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    var result = await resolveFileCode('$testPackageRootPath/lib/bar.dart', r'''
export 'package:test/src/foo.dart';
''');

    assertErrorsInTestResult(result, [
      error(diag.invalidExportOfInternalElement, 0, 35),
    ]);
  }

  void test_exporterInLibSrc() async {
    newFile('$testPackageRootPath/lib/src/foo.dart', r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    var result = await resolveFileCode(
      '$testPackageRootPath/lib/src/bar.dart',
      r'''
export 'package:test/src/foo.dart';
''',
    );

    assertNoErrorsInTestResult(result);
  }

  void test_internalIsInGeneratedLibSrc() async {
    newFile('$testPackageDartToolPath/lib/src/foo.dart', r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'package:test/src/foo.dart';
// [diag.invalidExportOfInternalElement][column 1][length 35] The member 'One' can't be exported as a part of a package's public API.
''');
  }

  @override
  void test_internalIsLibSrc() async {
    newFile(testPackageImplementationFilePath, r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'package:test/src/foo.dart';
// [diag.invalidExportOfInternalElement][column 1][length 35] The member 'One' can't be exported as a part of a package's public API.
''');
  }
}

@reflectiveTest
class InvalidExportOfInternalElement_PubPackageTest
    extends PubPackageResolutionTest
    with InvalidExportOfInternalElementTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
    newPubspecYamlFile(testPackageRootPath, r'''
name: test
version: 0.0.1
''');
  }

  void test_exporterIsInLib() async {
    newFile(testPackageImplementationFilePath, r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    var result = await resolveFileCode('$testPackageLibPath/bar.dart', r'''
export 'src/foo.dart';
''');

    assertErrorsInTestResult(result, [
      error(diag.invalidExportOfInternalElement, 0, 22),
    ]);
  }

  void test_exporterIsInLibSrc() async {
    newFile(testPackageImplementationFilePath, r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    var result = await resolveFileCode('$testPackageLibPath/src/bar.dart', r'''
export 'foo.dart';
''');

    assertNoErrorsInTestResult(result);
  }

  void test_exporterIsInTest() async {
    newFile(testPackageImplementationFilePath, r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    var result = await resolveFileCode(
      '$testPackageRootPath/test/foo_test.dart',
      r'''
export 'package:test/src/foo.dart';
''',
    );

    assertNoErrorsInTestResult(result);
  }

  void test_internalIsLibSrc() async {
    newFile(testPackageImplementationFilePath, r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'package:test/src/foo.dart';
// [diag.invalidExportOfInternalElement][column 1][length 35] The member 'One' can't be exported as a part of a package's public API.
''');
  }
}

mixin InvalidExportOfInternalElementTest on ContextResolutionTest {
  String get testPackageImplementationFilePath =>
      '$testPackageLibPath/src/foo.dart';

  String get testPackageLibPath;

  void test_hideCombinator_internalHidden() async {
    newFile(testPackageImplementationFilePath, r'''
import 'package:meta/meta.dart';
@internal class One {}
class Two {}
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'src/foo.dart' hide One;
''');
  }

  void test_hideCombinator_internalNotHidden() async {
    newFile(testPackageImplementationFilePath, r'''
import 'package:meta/meta.dart';
@internal class One {}
class Two {}
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'src/foo.dart' hide Two;
// [diag.invalidExportOfInternalElement][column 1][length 31] The member 'One' can't be exported as a part of a package's public API.
''');
  }

  void test_indirectlyViaFunction_messageText() async {
    newFile(testPackageImplementationFilePath, r'''
import 'package:meta/meta.dart';
@internal typedef int IntFunc(int x);
IntFunc func() => (int x) => x;
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'src/foo.dart' show func;
// [diag.invalidExportOfInternalElementIndirectly][column 1][length 32] The member 'IntFunc' can't be exported as a part of a package's public API, but is indirectly exported as part of the signature of 'func'.
''');
  }

  void test_indirectlyViaFunction_parameter() async {
    newFile(testPackageImplementationFilePath, r'''
import 'package:meta/meta.dart';
@internal typedef int IntFunc(int x);
int func(IntFunc f, int x) => f(x);
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'src/foo.dart' show func;
// [diag.invalidExportOfInternalElementIndirectly][column 1][length 32] The member 'IntFunc' can't be exported as a part of a package's public API, but is indirectly exported as part of the signature of 'func'.
''');
  }

  void test_indirectlyViaFunction_parameter_generic() async {
    newFile(testPackageImplementationFilePath, r'''
import 'package:meta/meta.dart';
@internal typedef IntFunc = int Function(int);
int func(IntFunc f, int x) => f(x);
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'src/foo.dart' show func;
// [diag.invalidExportOfInternalElementIndirectly][column 1][length 32] The member 'IntFunc' can't be exported as a part of a package's public API, but is indirectly exported as part of the signature of 'func'.
''');
  }

  void test_indirectlyViaFunction_parameter_generic_typeArg() async {
    newFile(testPackageImplementationFilePath, r'''
import 'package:meta/meta.dart';
@internal typedef IntFunc<T> = int Function(T);
int func(IntFunc<num> f, int x) => f(x);
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'src/foo.dart' show func;
// [diag.invalidExportOfInternalElementIndirectly][column 1][length 32] The member 'IntFunc' can't be exported as a part of a package's public API, but is indirectly exported as part of the signature of 'func'.
''');
  }

  void test_indirectlyViaFunction_returnType() async {
    newFile(testPackageImplementationFilePath, r'''
import 'package:meta/meta.dart';
@internal typedef int IntFunc(int x);
IntFunc func() => (int x) => x;
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'src/foo.dart' show func;
// [diag.invalidExportOfInternalElementIndirectly][column 1][length 32] The member 'IntFunc' can't be exported as a part of a package's public API, but is indirectly exported as part of the signature of 'func'.
''');
  }

  void test_indirectlyViaFunction_typeArgument_bounded() async {
    newFile(testPackageImplementationFilePath, r'''
import 'package:meta/meta.dart';
@internal typedef int IntFunc(int x);
void func<T extends IntFunc>() {}
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'src/foo.dart' show func;
// [diag.invalidExportOfInternalElementIndirectly][column 1][length 32] The member 'IntFunc' can't be exported as a part of a package's public API, but is indirectly exported as part of the signature of 'func'.
''');
  }

  void test_indirectlyViaFunction_typeArgument_unbounded() async {
    newFile(testPackageImplementationFilePath, r'''
import 'package:meta/meta.dart';
@internal typedef int IntFunc(int x);
void func<T>() {}
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'src/foo.dart' show func;
''');
  }

  void test_noCombinators() async {
    newFile(testPackageImplementationFilePath, r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'src/foo.dart';
// [diag.invalidExportOfInternalElement][column 1][length 22] The member 'One' can't be exported as a part of a package's public API.
''');
  }

  void test_noCombinators_indirectExport() async {
    newFile(testPackageImplementationFilePath, r'''
export 'bar.dart';
''');

    newFile('$testPackageLibPath/src/bar.dart', r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'src/foo.dart';
// [diag.invalidExportOfInternalElement][column 1][length 22] The member 'One' can't be exported as a part of a package's public API.
''');
  }

  void test_noCombinators_library() async {
    newFile(testPackageImplementationFilePath, r'''
@internal
library foo;

import 'package:meta/meta.dart';
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'src/foo.dart';
// [diag.invalidExportOfInternalElement][column 1][length 22] The member 'foo' can't be exported as a part of a package's public API.
''');
  }

  void test_noCombinators_library_notInternal() async {
    newFile(testPackageImplementationFilePath, r'''
library foo;
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'src/foo.dart';
''');
  }

  void test_noCombinators_noInternal() async {
    newFile(testPackageImplementationFilePath, r'''
class One {}
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'src/foo.dart';
''');
  }

  void test_noCombinators_topLevelVariable() async {
    newFile(testPackageImplementationFilePath, r'''
import 'package:meta/meta.dart';
@internal int x = 0;
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'src/foo.dart';
// [diag.invalidExportOfInternalElement][column 1][length 22] The member 'x' can't be exported as a part of a package's public API.
''');
  }

  void test_showCombinator_internalNotShown() async {
    newFile(testPackageImplementationFilePath, r'''
import 'package:meta/meta.dart';
@internal class One {}
class Two {}
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'src/foo.dart' show Two;
''');
  }

  void test_showCombinator_internalShown() async {
    newFile(testPackageImplementationFilePath, r'''
import 'package:meta/meta.dart';
@internal class One {}
class Two {}
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'src/foo.dart' show One;
// [diag.invalidExportOfInternalElement][column 1][length 31] The member 'One' can't be exported as a part of a package's public API.
''');
  }
}
