// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:matcher/matcher.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'file_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FileResolver_changeFile_Test);
    defineReflectiveTests(FileResolverTest);
  });
}

@reflectiveTest
class FileResolver_changeFile_Test extends FileResolutionTest {
  String aPath;
  String bPath;
  String cPath;

  @override
  void setUp() {
    super.setUp();
    aPath = convertPath('/workspace/dart/test/lib/a.dart');
    bPath = convertPath('/workspace/dart/test/lib/b.dart');
    cPath = convertPath('/workspace/dart/test/lib/c.dart');
  }

  test_changeFile_refreshedFiles() async {
    newFile(aPath, content: r'''
class A {}
''');

    newFile(bPath, content: r'''
class B {}
''');

    newFile(cPath, content: r'''
import 'a.dart';
import 'b.dart';
''');

    // First time we refresh everything.
    await resolveFile(cPath);
    _assertRefreshedFiles([aPath, bPath, cPath], withSdk: true);

    // Without changes we refresh nothing.
    await resolveFile(cPath);
    _assertRefreshedFiles([]);

    // We already know a.dart, refresh nothing.
    await resolveFile(aPath);
    _assertRefreshedFiles([]);

    // Change a.dart, refresh a.dart and c.dart, but not b.dart
    fileResolver.changeFile(aPath);
    await resolveFile(cPath);
    _assertRefreshedFiles([aPath, cPath]);
  }

  test_changeFile_resolution() async {
    newFile(aPath, content: r'''
class A {}
''');

    newFile(bPath, content: r'''
import 'a.dart';
A a;
B b;
''');

    result = await resolveFile(bPath);
    assertErrorsInResolvedUnit(result, [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 22, 1),
    ]);

    newFile(aPath, content: r'''
class A {}
class B {}
''');
    fileResolver.changeFile(aPath);

    result = await resolveFile(bPath);
    assertErrorsInResolvedUnit(result, []);
  }

  test_changePartFile_refreshedFiles() async {
    newFile(aPath, content: r'''
part 'b.dart';

class A {}
''');

    newFile(bPath, content: r'''
part of 'a.dart';

class B extends A {}
''');

    newFile(cPath, content: r'''
import 'a.dart';
''');

    // First time we refresh everything.
    await resolveFile(bPath);
    _assertRefreshedFiles([aPath, bPath], withSdk: true);
    // Change b.dart, refresh a.dart
    fileResolver.changeFile(bPath);
    await resolveFile(bPath);
    _assertRefreshedFiles([aPath, bPath]);
    // now with c.dart
    await resolveFile(cPath);
    _assertRefreshedFiles([cPath]);
    fileResolver.changeFile(bPath);
    await resolveFile(cPath);
    _assertRefreshedFiles([aPath, bPath, cPath]);
  }

  void _assertRefreshedFiles(List<String> expected, {bool withSdk = false}) {
    var expectedPlusSdk = expected.toSet();

    if (withSdk) {
      expectedPlusSdk
        ..add(convertPath('/sdk/lib/async/async.dart'))
        ..add(convertPath('/sdk/lib/async/stream.dart'))
        ..add(convertPath('/sdk/lib/core/core.dart'))
        ..add(convertPath('/sdk/lib/math/math.dart'));
    }

    var refreshedFiles = fileResolver.fsState.testView.refreshedFiles;
    expect(refreshedFiles, unorderedEquals(expectedPlusSdk));

    refreshedFiles.clear();
  }
}

@reflectiveTest
class FileResolverTest extends FileResolutionTest {
  test_analysisOptions_default_fromPackageUri() async {
    newFile('/workspace/dart/analysis_options/lib/default.yaml', content: r'''
analyzer:
  strong-mode:
    implicit-casts: false
''');

    await assertErrorsInCode(r'''
num a = 0;
int b = a;
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 19, 1),
    ]);
  }

  test_analysisOptions_file_inPackage() async {
    newFile('/workspace/dart/test/analysis_options.yaml', content: r'''
analyzer:
  strong-mode:
    implicit-casts: false
''');

    await assertErrorsInCode(r'''
num a = 0;
int b = a;
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 19, 1),
    ]);
  }

  test_analysisOptions_file_inThirdParty() async {
    newFile('/workspace/dart/analysis_options/lib/third_party.yaml',
        content: r'''
analyzer:
  strong-mode:
    implicit-casts: false
''');

    var aPath = convertPath('/workspace/third_party/dart/aaa/lib/a.dart');
    await assertErrorsInFile(aPath, r'''
num a = 0;
int b = a;
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 19, 1),
    ]);
  }

  test_analysisOptions_lints() async {
    newFile('/workspace/dart/analysis_options/lib/default.yaml', content: r'''
linter:
  rules:
    - omit_local_variable_types
''');

    var rule = Registry.ruleRegistry.getRule('omit_local_variable_types');

    await assertErrorsInCode(r'''
main() {
  int a = 0;
  a;
}
''', [
      error(rule.lintCode, 11, 9),
    ]);
  }

  test_analysisOptions_no() async {
    await assertNoErrorsInCode(r'''
num a = 0;
int b = a;
''');
  }

  test_basic() async {
    await assertNoErrorsInCode(r'''
int a = 0;
var b = 1 + 2;
''');
    assertType(findElement.topVar('a').type, 'int');
    assertElement(findNode.simple('int a'), intElement);

    assertType(findElement.topVar('b').type, 'int');
  }

  test_getErrors() {
    addTestFile(r'''
var a = b;
var foo = 0;
''');

    var result = getTestErrors();
    expect(result.path, convertPath('/workspace/dart/test/lib/test.dart'));
    expect(result.uri.toString(), 'package:dart.test/test.dart');
    assertErrorsInList(result.errors, [
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 8, 1),
    ]);
    expect(result.lineInfo.lineStarts, [0, 11, 24]);
  }

  test_getErrors_reuse() {
    addTestFile('var a = b;');

    var path = convertPath('/workspace/dart/test/lib/test.dart');

    // No resolved files yet.
    expect(fileResolver.testView.resolvedFiles, isEmpty);

    // No cached, will resolve once.
    expect(getTestErrors().errors, hasLength(1));
    expect(fileResolver.testView.resolvedFiles, [path]);

    // Has cached, will be not resolved again.
    expect(getTestErrors().errors, hasLength(1));
    expect(fileResolver.testView.resolvedFiles, [path]);

    // New resolver.
    // Still has cached, will be not resolved.
    createFileResolver();
    expect(getTestErrors().errors, hasLength(1));
    expect(fileResolver.testView.resolvedFiles, []);

    // Change the file, new resolver.
    // With changed file the previously cached result cannot be used.
    addTestFile('var a = c;');
    createFileResolver();
    expect(getTestErrors().errors, hasLength(1));
    expect(fileResolver.testView.resolvedFiles, [path]);

    // New resolver.
    // Still has cached, will be not resolved.
    createFileResolver();
    expect(getTestErrors().errors, hasLength(1));
    expect(fileResolver.testView.resolvedFiles, []);
  }

  test_getErrors_reuse_changeDependency() {
    newFile('/workspace/dart/test/lib/a.dart', content: r'''
var a = 0;
''');

    addTestFile(r'''
import 'a.dart';
var b = a.foo;
''');

    var path = convertPath('/workspace/dart/test/lib/test.dart');

    // No resolved files yet.
    expect(fileResolver.testView.resolvedFiles, isEmpty);

    // No cached, will resolve once.
    expect(getTestErrors().errors, hasLength(1));
    expect(fileResolver.testView.resolvedFiles, [path]);

    // Has cached, will be not resolved again.
    expect(getTestErrors().errors, hasLength(1));
    expect(fileResolver.testView.resolvedFiles, [path]);

    // Change the dependency, new resolver.
    // The signature of the result is different.
    // The previously cached result cannot be used.
    newFile('/workspace/dart/test/lib/a.dart', content: r'''
var a = 4.2;
''');
    createFileResolver();
    expect(getTestErrors().errors, hasLength(1));
    expect(fileResolver.testView.resolvedFiles, [path]);

    // New resolver.
    // Still has cached, will be not resolved.
    createFileResolver();
    expect(getTestErrors().errors, hasLength(1));
    expect(fileResolver.testView.resolvedFiles, []);
  }

  test_hint() async {
    await assertErrorsInCode(r'''
import 'dart:math';
''', [
      error(HintCode.UNUSED_IMPORT, 7, 11),
    ]);
  }

  test_resolve_part_of() async {
    newFile('/workspace/dart/test/lib/a.dart', content: r'''
part 'test.dart';

class A {
  int m;
}
''');

    await assertNoErrorsInCode(r'''
part of 'a.dart';

void func() {
  var a = A();
  print(a.m);
}
''');
  }

  test_reuse_compatibleOptions() async {
    var aPath = '/workspace/dart/aaa/lib/a.dart';
    var aResult = await assertErrorsInFile(aPath, r'''
num a = 0;
int b = a;
''', []);

    var bPath = '/workspace/dart/bbb/lib/a.dart';
    var bResult = await assertErrorsInFile(bPath, r'''
num a = 0;
int b = a;
''', []);

    // Both files use the same (default) analysis options.
    // So, when we resolve 'bbb', we can reuse the context after 'aaa'.
    expect(
      aResult.libraryElement.context,
      same(bResult.libraryElement.context),
    );
  }

  test_reuse_incompatibleOptions_implicitCasts() async {
    newFile('/workspace/dart/aaa/analysis_options.yaml', content: r'''
analyzer:
  strong-mode:
    implicit-casts: false
''');

    newFile('/workspace/dart/bbb/analysis_options.yaml', content: r'''
analyzer:
  strong-mode:
    implicit-casts: true
''');

    // Implicit casts are disabled in 'aaa'.
    var aPath = '/workspace/dart/aaa/lib/a.dart';
    await assertErrorsInFile(aPath, r'''
num a = 0;
int b = a;
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 19, 1),
    ]);

    // Implicit casts are enabled in 'bbb'.
    var bPath = '/workspace/dart/bbb/lib/a.dart';
    await assertErrorsInFile(bPath, r'''
num a = 0;
int b = a;
''', []);

    // Implicit casts are still disabled in 'aaa'.
    await assertErrorsInFile(aPath, r'''
num a = 0;
int b = a;
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 19, 1),
    ]);
  }

  test_unknown_uri() async {
    await assertErrorsInCode(r'''
import 'foo:bar';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 9),
    ]);
  }
}
