// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedMixinTest);
  });
}

@reflectiveTest
class DeprecatedMixinTest extends PubPackageResolutionTest {
  test_annotatedClass_typedef() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.mixin()
mixin class Foo {}
typedef Foo2 = Foo;
''');

    await assertErrorsInCode(
      r'''
import 'foo.dart';
class Bar with Foo {}
''',
      [error(WarningCode.deprecatedMixin, 34, 3)],
    );
  }

  test_annotatedClassTypeAlias() async {
    newFile('$testPackageLibPath/foo.dart', r'''
mixin M {}
@Deprecated.mixin()
mixin class Foo = Object with M;
''');

    await assertErrorsInCode(
      r'''
import 'foo.dart';
class Bar with Foo {}
''',
      [error(WarningCode.deprecatedMixin, 34, 3)],
    );
  }

  test_class() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.mixin()
mixin class Foo {}
''');

    await assertErrorsInCode(
      r'''
import 'foo.dart';
class Bar with Foo {}
''',
      [error(WarningCode.deprecatedMixin, 34, 3)],
    );
  }

  test_classTypeAlias() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.mixin()
mixin class Foo {}
''');

    await assertErrorsInCode(
      r'''
import 'foo.dart';
class Bar = Object with Foo;
''',
      [error(WarningCode.deprecatedMixin, 43, 3)],
    );
  }

  test_enum() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.mixin()
mixin class Foo {}
''');

    await assertErrorsInCode(
      r'''
import 'foo.dart';
enum Bar with Foo {
  one, two;
}
''',
      [error(WarningCode.deprecatedMixin, 33, 3)],
    );
  }

  test_insideLibrary() async {
    await assertNoErrorsInCode(r'''
@Deprecated.mixin()
mixin class Foo {}
class Bar with Foo {}
''');
  }

  test_noAnnotation() async {
    newFile('$testPackageLibPath/foo.dart', r'''
mixin class Foo {}
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
class Bar with Foo {}
''');
  }
}
