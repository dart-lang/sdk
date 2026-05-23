// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinOnSealedClassTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MixinOnSealedClassTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_mixinOnSealedClass() async {
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
mixin Bar on Foo {}
// [diag.mixinOnSealedClass][column 1][length 19] The class 'Foo' shouldn't be used as a mixin constraint because it is sealed, and any class mixing in this mixin must have 'Foo' as a superclass.
''');
  }

  test_withinLibrary_OK() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@sealed class Foo {}
mixin Bar on Foo {}
''');
  }

  test_withinPackageLibDirectory_OK() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
@sealed class Foo {}
''');

    var lib2 = newFile('$testPackageLibPath/src/lib2.dart', r'''
import '../lib1.dart';
mixin Bar on Foo {}
''');

    var result = await resolveFile2(lib1);
    assertNoErrorsInTestResult(result);

    result = await resolveFile2(lib2);
    assertNoErrorsInTestResult(result);
  }

  test_withinPackageTestDirectory_OK() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
@sealed class Foo {}
''');

    var lib2 = newFile('$testPackageRootPath/test/lib2.dart', r'''
import 'package:test/lib1.dart';
mixin Bar on Foo {}
''');

    var result = await resolveFile2(lib1);
    assertNoErrorsInTestResult(result);

    result = await resolveFile2(lib2);
    assertNoErrorsInTestResult(result);
  }

  test_withinPart_OK() async {
    var lib1 = newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
part 'part1.dart';
@sealed class Foo {}
''');

    var lib2 = newFile('$testPackageLibPath/part1.dart', r'''
part of 'lib1.dart';
mixin Bar on Foo {}
''');

    var result = await resolveFile2(lib1);
    assertNoErrorsInTestResult(result);

    result = await resolveFile2(lib2);
    assertNoErrorsInTestResult(result);
  }
}
