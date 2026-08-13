// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FinalClassImplementedOutsideOfLibraryTest);
  });
}

@reflectiveTest
class FinalClassImplementedOutsideOfLibraryTest
    extends PubPackageResolutionTest {
  test_class_inside() async {
    await resolveTestCodeWithDiagnostics(r'''
final class Foo {}
final class Bar implements Foo {}
''');
  }

  test_class_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
final class Bar implements Foo {}
//                         ^^^
// [diag.finalClassImplementedOutsideOfLibrary] The class 'Foo' can't be implemented outside of its library because it's a final class.
''');
  }

  test_class_outside_viaLanguage219AndCore() async {
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
final class B implements A {
//                       ^
// [diag.finalClassImplementedOutsideOfLibrary] The class 'MapEntry' can't be implemented outside of its library because it's a final class.
  int get key => 0;
  int get value => 1;
}
''');
  }

  test_class_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final class Foo {}
typedef FooTypedef = Foo;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
final class Bar implements FooTypedef {}
//                         ^^^^^^^^^^
// [diag.finalClassImplementedOutsideOfLibrary] The class 'Foo' can't be implemented outside of its library because it's a final class.
''');
  }

  test_class_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
final class Bar implements FooTypedef {}
//                         ^^^^^^^^^^
// [diag.finalClassImplementedOutsideOfLibrary] The class 'Foo' can't be implemented outside of its library because it's a final class.
''');
  }

  test_enum_inside() async {
    await resolveTestCodeWithDiagnostics(r'''
final class Foo {}
enum Bar implements Foo { bar }
''');
  }

  test_enum_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
enum Bar implements Foo { bar }
//                  ^^^
// [diag.finalClassImplementedOutsideOfLibrary] The class 'Foo' can't be implemented outside of its library because it's a final class.
''');
  }

  test_enum_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final class Foo {}
typedef FooTypedef = Foo;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
enum Bar implements FooTypedef { bar }
//                  ^^^^^^^^^^
// [diag.finalClassImplementedOutsideOfLibrary] The class 'Foo' can't be implemented outside of its library because it's a final class.
''');
  }

  test_enum_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
enum Bar implements FooTypedef { bar }
//                  ^^^^^^^^^^
// [diag.finalClassImplementedOutsideOfLibrary] The class 'Foo' can't be implemented outside of its library because it's a final class.
''');
  }

  test_enum_subtypeOfFinal_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final class Foo {}
class Bar implements Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
enum Bar2 implements Bar { bar }
''');
  }
}
