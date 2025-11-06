// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedExtendTest);
  });
}

@reflectiveTest
class DeprecatedExtendTest extends PubPackageResolutionTest {
  test_annotatedClass() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.extend()
class Foo {}
''');

    await assertErrorsInCode(
      r'''
import 'foo.dart';
class Bar extends Foo {}
''',
      [error(WarningCode.deprecatedExtend, 37, 3)],
    );
  }

  test_annotatedClass_indirect() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.extend()
class Foo {}
class Bar extends Foo {}
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
class Baz extends Bar {}
''');
  }

  test_annotatedClass_typedef() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.extend()
class Foo {}
typedef Foo2 = Foo;
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
class Bar extends Foo2 {}
''');
  }

  test_annotatedClassTypeAlias() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.extend()
class Foo = Object with M;
mixin M {}
''');

    await assertErrorsInCode(
      r'''
import 'foo.dart';
class Bar extends Foo {}
''',
      [error(WarningCode.deprecatedExtend, 37, 3)],
    );
  }

  test_classTypeAlias() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.extend()
class Foo {}
''');

    await assertErrorsInCode(
      r'''
import 'foo.dart';
mixin M {}
class Bar = Foo with M;
''',
      [error(WarningCode.deprecatedExtend, 42, 3)],
    );
  }

  test_insideLibrary() async {
    await assertNoErrorsInCode(r'''
@Deprecated.extend()
class Foo {}
class Bar extends Foo {}
''');
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
