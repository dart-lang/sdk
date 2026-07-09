// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassUsedAsMixinTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ClassUsedAsMixinTest extends PubPackageResolutionTest {
  test_coreLib() async {
    await resolveTestCodeWithDiagnostics(r'''
class Bar with Comparable<int> {
//             ^^^^^^^^^^^^^^^
// [diag.classUsedAsMixin] The class 'Comparable' can't be used as a mixin because it's neither a mixin class nor a mixin.
  int compareTo(int x) => 0;
}
''');
  }

  test_coreLib_dartCoreEnum() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A with Enum {}
//                    ^^^^
// [diag.classUsedAsMixin] The class 'Enum' can't be used as a mixin because it's neither a mixin class nor a mixin.
abstract class B = Object with Enum;
//                             ^^^^
// [diag.classUsedAsMixin] The class 'Enum' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }

  test_coreLib_dartCoreEnum_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
abstract class A with Enum {}
abstract class B = Object with Enum;
''');
  }

  test_coreLib_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
class Bar with Comparable<int> {
  int compareTo(int x) => 0;
}
''');
  }

  test_inside() async {
    await resolveTestCodeWithDiagnostics(r'''
class Foo {}
class Bar with Foo {}
//             ^^^
// [diag.classUsedAsMixin] The class 'Foo' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }

  test_inside_class_hasGenerativeConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() {}
}
class B extends Object with A {}
//                          ^
// [diag.classUsedAsMixin] The class 'A' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }

  test_inside_classTypeAlias_hasGenerativeConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() {}
}
class B = Object with A;
//                    ^
// [diag.classUsedAsMixin] The class 'A' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }

  test_inside_enum_hasGenerativeConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() {}
}

enum E with A {
//          ^
// [diag.classUsedAsMixin] The class 'A' can't be used as a mixin because it's neither a mixin class nor a mixin.
  v
}
''');
  }

  test_inside_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
class Foo {}
class Bar with Foo {}
''');
  }

  test_inside_mixinClass() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class Foo {}
class Bar with Foo {}
''');
  }

  test_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar with Foo {}
//             ^^^
// [diag.classUsedAsMixin] The class 'Foo' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }

  test_outside_language219() async {
    newFile('$testPackageLibPath/foo.dart', r'''
// @dart = 2.19
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar with Foo {}
''');
  }

  test_outside_language219_mixedIn() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
import 'foo.dart';
class Bar with Foo {}
//             ^^^
// [diag.classUsedAsMixin] The class 'Foo' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }

  test_outside_mixinClass() async {
    newFile('$testPackageLibPath/foo.dart', r'''
mixin class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar with Foo {}
''');
  }

  test_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class Foo {}
typedef FooTypedef = Foo;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar with FooTypedef {}
//             ^^^^^^^^^^
// [diag.classUsedAsMixin] The class 'Foo' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }

  test_outside_viaTypedef_inside_language219() async {
    newFile('$testPackageLibPath/foo.dart', r'''
// @dart = 2.19
class Foo {}
typedef FooTypedef = Foo;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar with FooTypedef {}
''');
  }

  test_outside_viaTypedef_inside_mixinClass() async {
    newFile('$testPackageLibPath/foo.dart', r'''
mixin class Foo {}
typedef FooTypedef = Foo;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar with FooTypedef {}
''');
  }

  test_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
class Bar with FooTypedef {}
//             ^^^^^^^^^^
// [diag.classUsedAsMixin] The class 'Foo' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }

  test_outside_viaTypedef_outside_language219() async {
    newFile('$testPackageLibPath/foo.dart', r'''
// @dart = 2.19
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
class Bar with FooTypedef {}
''');
  }

  test_outside_viaTypedef_outside_mixinClass() async {
    newFile('$testPackageLibPath/foo.dart', r'''
mixin class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
class Bar with FooTypedef {}
''');
  }
}
