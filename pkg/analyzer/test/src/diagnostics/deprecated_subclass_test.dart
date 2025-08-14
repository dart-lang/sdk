// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedSubclassTest);
  });
}

@reflectiveTest
class DeprecatedSubclassTest extends PubPackageResolutionTest {
  test_enumImplementsClass() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.subclass()
class Foo {}
''');

    await assertErrorsInCode(
      r'''
import 'foo.dart';
enum Bar implements Foo { one; }
''',
      [error(WarningCode.deprecatedSubclass, 39, 3)],
    );
  }

  test_extendsClass() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.subclass()
class Foo {}
''');

    await assertErrorsInCode(
      r'''
import 'foo.dart';
class Bar extends Foo {}
''',
      [error(WarningCode.deprecatedSubclass, 37, 3)],
    );
  }

  test_implementsClass() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.subclass()
class Foo {}
''');

    await assertErrorsInCode(
      r'''
import 'foo.dart';
class Bar implements Foo {}
''',
      [error(WarningCode.deprecatedSubclass, 40, 3)],
    );
  }

  test_implementsMixin() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.subclass()
mixin Foo {}
''');

    await assertErrorsInCode(
      r'''
import 'foo.dart';
class Bar implements Foo {}
''',
      [error(WarningCode.deprecatedSubclass, 40, 3)],
    );
  }

  test_insideLibrary() async {
    await assertNoErrorsInCode(r'''
@Deprecated.subclass()
class Foo {}
class Bar extends Foo {}
''');
  }

  test_language212_mixedIn() async {
    newFile('$testPackageLibPath/foo.dart', r'''
// @dart = 2.12
@Deprecated.subclass()
class Foo {}
''');

    await assertErrorsInCode(
      r'''
// @dart = 2.12
import 'foo.dart';
class Bar extends Object with Foo {}
''',
      [error(WarningCode.deprecatedSubclass, 65, 3)],
    );
  }

  test_mixinImplementsClass() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.subclass()
class Foo {}
''');

    await assertErrorsInCode(
      r'''
import 'foo.dart';
mixin Bar implements Foo {}
''',
      [error(WarningCode.deprecatedSubclass, 40, 3)],
    );
  }

  test_mixinOnClass() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.subclass()
class Foo {}
''');

    await assertErrorsInCode(
      r'''
import 'foo.dart';
mixin Bar on Foo {}
''',
      [error(WarningCode.deprecatedSubclass, 32, 3)],
    );
  }

  test_noAnnotation() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class Foo {}
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
class Bar extends Foo {}
''');
  }
}
