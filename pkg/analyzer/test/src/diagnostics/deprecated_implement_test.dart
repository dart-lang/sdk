// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedImplementTest);
  });
}

@reflectiveTest
class DeprecatedImplementTest extends PubPackageResolutionTest {
  test_annotatedClass() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.implement()
class Foo {}
''');

    await assertErrorsInCode(
      r'''
import 'foo.dart';
class Bar implements Foo {}
''',
      [error(WarningCode.DEPRECATED_IMPLEMENT, 40, 3)],
    );
  }

  test_annotatedClass_indirect() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.implement()
class Foo {}
class Bar extends Foo {}
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
class Baz implements Bar {}
''');
  }

  test_annotatedClass_typedef() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.implement()
class Foo {}
typedef Foo2 = Foo;
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
class Bar implements Foo2 {}
''');
  }

  test_annotatedClassTypeAlias() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.implement()
class Foo  = Object with M;
mixin M {}
''');

    await assertErrorsInCode(
      r'''
import 'foo.dart';
class Bar implements Foo {}
''',
      [error(WarningCode.DEPRECATED_IMPLEMENT, 40, 3)],
    );
  }

  test_classTypeAlias() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.implement()
class Foo {}
''');

    await assertErrorsInCode(
      r'''
import 'foo.dart';
mixin M {}
class Bar = Object with M implements Foo;
''',
      [error(WarningCode.DEPRECATED_IMPLEMENT, 67, 3)],
    );
  }

  test_enum() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.implement()
class Foo {}
''');

    await assertErrorsInCode(
      r'''
import 'foo.dart';
enum Bar implements Foo { one; }
''',
      [error(WarningCode.DEPRECATED_IMPLEMENT, 39, 3)],
    );
  }

  test_insideLibrary() async {
    await assertNoErrorsInCode(r'''
@Deprecated.implement()
class Foo {}
class Bar implements Foo {}
''');
  }

  test_noAnnotation() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class Foo {}
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
class Bar implements Foo {}
''');
  }
}
