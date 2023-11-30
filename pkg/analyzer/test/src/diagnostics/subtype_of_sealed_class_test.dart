// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SubtypeOfSealedClassTest);
  });
}

@reflectiveTest
class SubtypeOfSealedClassTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_extendingSealedClass() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'foo', rootPath: '$workspaceRootPath/foo'),
      meta: true,
    );

    newFile('$workspaceRootPath/foo/lib/foo.dart', r'''
import 'package:meta/meta.dart';
@sealed class Foo {}
''');

    await assertErrorsInCode(r'''
import 'package:foo/foo.dart';
class Bar extends Foo {}
''', [
      error(WarningCode.SUBTYPE_OF_SEALED_CLASS, 31, 24),
    ]);
  }

  test_implementingSealedClass() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'foo', rootPath: '$workspaceRootPath/foo'),
      meta: true,
    );

    newFile('$workspaceRootPath/foo/lib/foo.dart', r'''
import 'package:meta/meta.dart';
@sealed class Foo {}
''');

    await assertErrorsInCode(r'''
import 'package:foo/foo.dart';
class Bar implements Foo {}
''', [
      error(WarningCode.SUBTYPE_OF_SEALED_CLASS, 31, 27),
    ]);
  }

  test_mixinApplicationOfSealedClass() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'foo', rootPath: '$workspaceRootPath/foo'),
      meta: true,
    );

    newFile('$workspaceRootPath/foo/lib/foo.dart', r'''
// @dart = 2.19
import 'package:meta/meta.dart';
@sealed class Foo {}
''');

    await assertErrorsInCode(r'''
import 'package:foo/foo.dart';
class Bar1 {}
class Bar2 = Bar1 with Foo;
''', [
      error(WarningCode.SUBTYPE_OF_SEALED_CLASS, 45, 27),
    ]);
  }

  test_mixinApplicationOfSealedMixin() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'foo', rootPath: '$workspaceRootPath/foo'),
      meta: true,
    );

    newFile('$workspaceRootPath/foo/lib/foo.dart', r'''
import 'package:meta/meta.dart';
@sealed mixin Foo {}
''');

    await assertErrorsInCode(r'''
import 'package:foo/foo.dart';
class Bar1 {}
class Bar2 = Bar1 with Foo;
''', [
      error(WarningCode.SUBTYPE_OF_SEALED_CLASS, 45, 27),
    ]);
  }

  test_mixingInWithSealedMixin() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'foo', rootPath: '$workspaceRootPath/foo'),
      meta: true,
    );

    newFile('$workspaceRootPath/foo/lib/foo.dart', r'''
import 'package:meta/meta.dart';
@sealed mixin Foo {}
''');

    await assertErrorsInCode(r'''
import 'package:foo/foo.dart';
class Bar extends Object with Foo {}
''', [
      error(WarningCode.SUBTYPE_OF_SEALED_CLASS, 31, 36),
    ]);
  }

  test_mixinImplementsSealedClass() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'foo', rootPath: '$workspaceRootPath/foo'),
      meta: true,
    );

    newFile('$workspaceRootPath/foo/lib/foo.dart', r'''
import 'package:meta/meta.dart';
@sealed class Foo {}
''');

    await assertErrorsInCode(r'''
import 'package:foo/foo.dart';
mixin Bar implements Foo {}
''', [
      error(WarningCode.SUBTYPE_OF_SEALED_CLASS, 31, 27),
    ]);
  }

  test_withinLibrary_language219() async {
    await assertNoErrorsInCode(r'''
// @dart = 2.19
import 'package:meta/meta.dart';
@sealed class Foo {}

class Bar1 extends Foo {}
class Bar2 implements Foo {}
class Bar4 = Bar1 with Foo;
mixin Bar5 implements Foo {}
''');
  }

  test_withinPackageLibDirectory_language219() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.19
import 'package:meta/meta.dart';
@sealed class Foo {}
''');

    await resolveFileCode('$testPackageLibPath/src/b.dart', r'''
import '../a.dart';
class Bar1 extends Foo {}
class Bar2 implements Foo {}
class Bar4 = Bar1 with Foo;
mixin Bar5 implements Foo {}
''');
    assertNoErrorsInResult();
  }

  test_withinPackageTestDirectory_language219() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.19
import 'package:meta/meta.dart';
@sealed class Foo {}
''');

    await resolveFileCode('$testPackageRootPath/test/test.dart', r'''
import 'package:test/a.dart';

class Bar1 extends Foo {}
class Bar2 implements Foo {}
class Bar4 = Bar1 with Foo;
mixin Bar5 implements Foo {}
''');
    assertNoErrorsInResult();
  }

  test_withinPart_language219() async {
    final lib = newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.19
import 'package:meta/meta.dart';
part 'b.dart';
@sealed class Foo {}
''');

    final part = newFile('$testPackageLibPath/b.dart', r'''
// @dart = 2.19
part of 'a.dart';
class Bar1 extends Foo {}
class Bar2 implements Foo {}
class Bar4 = Bar1 with Foo;
mixin Bar5 implements Foo {}
''');

    await resolveFile2(lib);
    assertNoErrorsInResult();

    await resolveFile2(part);
    assertNoErrorsInResult();
  }
}
