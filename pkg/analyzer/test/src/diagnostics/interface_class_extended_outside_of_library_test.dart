// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InterfaceClassExtendedOutsideOfLibraryTest);
  });
}

@reflectiveTest
class InterfaceClassExtendedOutsideOfLibraryTest
    extends PubPackageResolutionTest {
  test_inside() async {
    await assertNoErrorsInCode(r'''
interface class Foo {}
class Bar extends Foo {}
''');
  }

  test_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
interface class Foo {}
''');

    await assertErrorsInCode(
      r'''
import 'foo.dart';
class Bar extends Foo {}
''',
      [error(diag.interfaceClassExtendedOutsideOfLibrary, 37, 3)],
    );
  }

  test_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
interface class Foo {}
typedef FooTypedef = Foo;
''');

    await assertErrorsInCode(
      r'''
import 'foo.dart';
class Bar extends FooTypedef {}
''',
      [error(diag.interfaceClassExtendedOutsideOfLibrary, 37, 10)],
    );
  }

  test_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
interface class Foo {}
''');

    await assertErrorsInCode(
      r'''
import 'foo.dart';
typedef FooTypedef = Foo;
class Bar extends FooTypedef {}
''',
      [error(diag.interfaceClassExtendedOutsideOfLibrary, 63, 10)],
    );
  }

  test_subtypeOfBase_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
interface class Foo {}
class Bar extends Foo {}
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
class Bar2 extends Bar {}
''');
  }
}
