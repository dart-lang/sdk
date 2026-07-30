// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SubtypeOfSealedClassTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
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
        ..add(name: 'foo', rootFolder: getFolder('$workspaceRootPath/foo')),
      meta: true,
    );

    newFile('$workspaceRootPath/foo/lib/foo.dart', r'''
import 'package:meta/meta.dart';
@sealed class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:foo/foo.dart';
class Bar extends Foo {}
// [diag.subtypeOfSealedClass][column 1][length 24] The class 'Foo' shouldn't be extended, mixed in, or implemented because it's sealed.
''');
  }

  test_implementingSealedClass() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'foo', rootFolder: getFolder('$workspaceRootPath/foo')),
      meta: true,
    );

    newFile('$workspaceRootPath/foo/lib/foo.dart', r'''
import 'package:meta/meta.dart';
@sealed class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:foo/foo.dart';
class Bar implements Foo {}
// [diag.subtypeOfSealedClass][column 1][length 27] The class 'Foo' shouldn't be extended, mixed in, or implemented because it's sealed.
''');
  }

  test_mixinApplicationOfSealedClass() async {
    var fooRoot = getFolder('$workspaceRootPath/foo');
    var packageConfig = PackageConfigFileBuilder()
      ..add(name: 'foo', rootFolder: fooRoot)
      ..add(name: 'meta', rootFolder: addMeta().parent);
    writeTestPackageConfig(packageConfig);
    writePackageConfig(fooRoot.path, packageConfig);

    await resolveFilesWithDiagnostics({
      getFile('$workspaceRootPath/foo/lib/foo.dart'): r'''
// %before-language-feature: class-modifiers
import 'package:meta/meta.dart';
@sealed class Foo {}
''',
      testFile: r'''
import 'package:foo/foo.dart';
class Bar1 {}
class Bar2 = Bar1 with Foo;
// [diag.subtypeOfSealedClass][column 1][length 27] The class 'Foo' shouldn't be extended, mixed in, or implemented because it's sealed.
''',
    });
  }

  test_mixinApplicationOfSealedMixin() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'foo', rootFolder: getFolder('$workspaceRootPath/foo')),
      meta: true,
    );

    newFile('$workspaceRootPath/foo/lib/foo.dart', r'''
import 'package:meta/meta.dart';
@sealed mixin Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:foo/foo.dart';
class Bar1 {}
class Bar2 = Bar1 with Foo;
// [diag.subtypeOfSealedClass][column 1][length 27] The class 'Foo' shouldn't be extended, mixed in, or implemented because it's sealed.
''');
  }

  test_mixingInWithSealedMixin() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'foo', rootFolder: getFolder('$workspaceRootPath/foo')),
      meta: true,
    );

    newFile('$workspaceRootPath/foo/lib/foo.dart', r'''
import 'package:meta/meta.dart';
@sealed mixin Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:foo/foo.dart';
class Bar extends Object with Foo {}
// [diag.subtypeOfSealedClass][column 1][length 36] The class 'Foo' shouldn't be extended, mixed in, or implemented because it's sealed.
''');
  }

  test_mixinImplementsSealedClass() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'foo', rootFolder: getFolder('$workspaceRootPath/foo')),
      meta: true,
    );

    newFile('$workspaceRootPath/foo/lib/foo.dart', r'''
import 'package:meta/meta.dart';
@sealed class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:foo/foo.dart';
mixin Bar implements Foo {}
// [diag.subtypeOfSealedClass][column 1][length 27] The class 'Foo' shouldn't be extended, mixed in, or implemented because it's sealed.
''');
  }

  test_withinLibrary_beforeClassModifiers() async {
    await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: class-modifiers
import 'package:meta/meta.dart';
@sealed class Foo {}

class Bar1 extends Foo {}
class Bar2 implements Foo {}
class Bar4 = Bar1 with Foo;
mixin Bar5 implements Foo {}
''');
  }

  test_withinPackageLibDirectory_beforeClassModifiers() async {
    await resolveFilesWithDiagnostics({
      getFile('$testPackageLibPath/a.dart'): r'''
// %before-language-feature: class-modifiers
import 'package:meta/meta.dart';
@sealed class Foo {}
''',
      getFile('$testPackageLibPath/src/b.dart'): r'''
import '../a.dart';
class Bar1 extends Foo {}
class Bar2 implements Foo {}
class Bar4 = Bar1 with Foo;
mixin Bar5 implements Foo {}
''',
    });
  }

  test_withinPackageTestDirectory_beforeClassModifiers() async {
    await resolveFilesWithDiagnostics({
      getFile('$testPackageLibPath/a.dart'): r'''
// %before-language-feature: class-modifiers
import 'package:meta/meta.dart';
@sealed class Foo {}
''',
      getFile('$testPackageRootPath/test/test.dart'): r'''
import 'package:test/a.dart';

class Bar1 extends Foo {}
class Bar2 implements Foo {}
class Bar4 = Bar1 with Foo;
mixin Bar5 implements Foo {}
''',
    });
  }

  test_withinPart_beforeClassModifiers() async {
    var lib = getFile('$testPackageLibPath/a.dart');
    var part = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      lib: r'''
// %before-language-feature: class-modifiers
import 'package:meta/meta.dart';
part 'b.dart';
@sealed class Foo {}
''',
      part: r'''
// %before-language-feature: class-modifiers
part of 'a.dart';
class Bar1 extends Foo {}
class Bar2 implements Foo {}
class Bar4 = Bar1 with Foo;
mixin Bar5 implements Foo {}
''',
    });
  }
}
