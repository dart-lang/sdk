// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FinalClassExtendedOutsideOfLibraryTest);
  });
}

@reflectiveTest
class FinalClassExtendedOutsideOfLibraryTest extends PubPackageResolutionTest {
  test_inside() async {
    await resolveTestCodeWithDiagnostics(r'''
final class Foo {}
final class Bar extends Foo {}
''');
  }

  test_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
final class Bar extends Foo {}
//                      ^^^
// [diag.finalClassExtendedOutsideOfLibrary] The class 'Foo' can't be extended outside of its library because it's a final class.
''');
  }

  test_outside_viaLanguage219AndCore() async {
    // There is no error when extending a pre-feature class that subtypes a
    // class in the core libraries.
    var a = getFile('$testPackageLibPath/a.dart');
    await resolveFileWithDiagnostics(a, r'''
// @dart=2.19
import 'dart:core';
class A implements MapEntry<int, int> {
  int get key => 0;
  int get value => 1;
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
final class B extends A {
  int get key => 0;
  int get value => 1;
}
''');
  }

  test_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final class Foo {}
typedef FooTypedef = Foo;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
final class Bar extends FooTypedef {}
//                      ^^^^^^^^^^
// [diag.finalClassExtendedOutsideOfLibrary] The class 'Foo' can't be extended outside of its library because it's a final class.
''');
  }

  test_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
final class Bar extends FooTypedef {}
//                      ^^^^^^^^^^
// [diag.finalClassExtendedOutsideOfLibrary] The class 'Foo' can't be extended outside of its library because it's a final class.
''');
  }
}
