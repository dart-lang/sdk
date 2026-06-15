// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BaseClassImplementedOutsideOfLibraryTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class BaseClassImplementedOutsideOfLibraryTest
    extends PubPackageResolutionTest {
  test_class_inside() async {
    await resolveTestCodeWithDiagnostics(r'''
base class Foo {}
base class Bar implements Foo {}
''');
  }

  test_class_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
base class Bar implements Foo {}
//                        ^^^
// [diag.baseClassImplementedOutsideOfLibrary] The class 'Foo' can't be implemented outside of its library because it's a base class.
''');
  }

  test_class_outside_sealed() async {
    var a = getFile('$testPackageLibPath/a.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
base class A {}
//         ^
// [context 1] The type 'B' is a subtype of 'A', and 'A' is defined here.
''',
      testFile: r'''
import 'a.dart';
sealed class B extends A {}
base class C implements B {}
//                      ^
// [diag.baseClassImplementedOutsideOfLibrary][context 1] The class 'A' can't be implemented outside of its library because it's a base class.
''',
    });
  }

  test_class_outside_sealed_noBase() async {
    // Instead of emitting [SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED], we
    // tell the user that they can't implement an indirect base supertype.
    var a = getFile('$testPackageLibPath/a.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
base class A {}
//         ^
// [context 1] The type 'B' is a subtype of 'A', and 'A' is defined here.
''',
      testFile: r'''
import 'a.dart';
sealed class B extends A {}
class C implements B {}
//                 ^
// [diag.baseClassImplementedOutsideOfLibrary][context 1] The class 'A' can't be implemented outside of its library because it's a base class.
''',
    });
  }

  test_class_outside_viaExtends() async {
    newFile('$testPackageLibPath/a.dart', r'''
base class A {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';
base class B extends A {}
base class C implements B {}
//                      ^
// [diag.baseClassImplementedOutsideOfLibrary] The class 'A' can't be implemented outside of its library because it's a base class.
''');
  }

  test_class_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base class Foo {}
typedef FooTypedef = Foo;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
base class Bar implements FooTypedef {}
//                        ^^^^^^^^^^
// [diag.baseClassImplementedOutsideOfLibrary] The class 'Foo' can't be implemented outside of its library because it's a base class.
''');
  }

  test_class_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
base class Bar implements FooTypedef {}
//                        ^^^^^^^^^^
// [diag.baseClassImplementedOutsideOfLibrary] The class 'Foo' can't be implemented outside of its library because it's a base class.
''');
  }

  test_classTypeAlias_inside() async {
    await resolveTestCodeWithDiagnostics(r'''
base class A {}
sealed class B extends A {}
mixin M {}
base class C = Object with M implements B;
''');
  }

  test_classTypeAlias_outside() async {
    var a = getFile('$testPackageLibPath/a.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
base class A {}
//         ^
// [context 1] The type 'B' is a subtype of 'A', and 'A' is defined here.
''',
      testFile: r'''
import 'a.dart';
sealed class B extends A {}
mixin M {}
base class C = Object with M implements B;
//                                      ^
// [diag.baseClassImplementedOutsideOfLibrary][context 1] The class 'A' can't be implemented outside of its library because it's a base class.
''',
    });
  }

  test_enum_inside() async {
    await resolveTestCodeWithDiagnostics(r'''
base class Foo {}
enum Bar implements Foo { bar }
''');
  }

  test_enum_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
enum Bar implements Foo { bar }
//                  ^^^
// [diag.baseClassImplementedOutsideOfLibrary] The class 'Foo' can't be implemented outside of its library because it's a base class.
''');
  }

  test_enum_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base class Foo {}
typedef FooTypedef = Foo;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
enum Bar implements FooTypedef { bar }
//                  ^^^^^^^^^^
// [diag.baseClassImplementedOutsideOfLibrary] The class 'Foo' can't be implemented outside of its library because it's a base class.
''');
  }

  test_enum_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
enum Bar implements FooTypedef { bar }
//                  ^^^^^^^^^^
// [diag.baseClassImplementedOutsideOfLibrary] The class 'Foo' can't be implemented outside of its library because it's a base class.
''');
  }

  test_mixin_inside() async {
    await resolveTestCodeWithDiagnostics(r'''
base class Foo {}
base mixin Bar implements Foo {}
''');
  }

  test_mixin_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
base mixin Bar implements Foo {}
//                        ^^^
// [diag.baseClassImplementedOutsideOfLibrary] The class 'Foo' can't be implemented outside of its library because it's a base class.
''');
  }

  test_mixin_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base class Foo {}
typedef FooTypedef = Foo;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
base mixin Bar implements FooTypedef {}
//                        ^^^^^^^^^^
// [diag.baseClassImplementedOutsideOfLibrary] The class 'Foo' can't be implemented outside of its library because it's a base class.
''');
  }

  test_mixin_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
base mixin Bar implements FooTypedef {}
//                        ^^^^^^^^^^
// [diag.baseClassImplementedOutsideOfLibrary] The class 'Foo' can't be implemented outside of its library because it's a base class.
''');
  }
}
