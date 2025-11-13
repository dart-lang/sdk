// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplementsDisallowedClassTest);
  });
}

@reflectiveTest
class ImplementsDisallowedClassTest extends PubPackageResolutionTest {
  test_class_bool() async {
    await assertErrorsInCode(
      '''
class A implements bool {}
''',
      [error(diag.implementsDisallowedClass, 19, 4)],
    );
  }

  test_class_dartCoreEnum_abstract() async {
    await assertNoErrorsInCode('''
abstract class A implements Enum {}
''');
  }

  test_class_dartCoreEnum_language216_abstract() async {
    await assertErrorsInCode(
      '''
// @dart = 2.16
abstract class A implements Enum {}
''',
      [error(diag.implementsDisallowedClass, 44, 4)],
    );
  }

  test_class_dartCoreEnum_language216_concrete() async {
    await assertErrorsInCode(
      '''
// @dart = 2.16
class A implements Enum {}
''',
      [error(diag.implementsDisallowedClass, 35, 4)],
    );
  }

  test_class_double() async {
    await assertErrorsInCode(
      '''
class A implements double {}
''',
      [error(diag.implementsDisallowedClass, 19, 6)],
    );
  }

  test_class_FutureOr() async {
    await assertErrorsInCode(
      '''
import 'dart:async';
class A implements FutureOr {}
''',
      [error(diag.implementsDisallowedClass, 40, 8)],
    );
  }

  test_class_FutureOr_typeArgument() async {
    await assertErrorsInCode(
      '''
import 'dart:async';
class A implements FutureOr<int> {}
''',
      [error(diag.implementsDisallowedClass, 40, 13)],
    );
  }

  test_class_FutureOr_typedef() async {
    await assertErrorsInCode(
      '''
import 'dart:async';
typedef F = FutureOr<void>;
class A implements F {}
''',
      [error(diag.implementsDisallowedClass, 68, 1)],
    );
  }

  test_class_FutureOr_typeVariable() async {
    await assertErrorsInCode(
      '''
import 'dart:async';
class A<T> implements FutureOr<T> {}
''',
      [error(diag.implementsDisallowedClass, 43, 11)],
    );
  }

  test_class_int() async {
    await assertErrorsInCode(
      '''
class A implements int {}
''',
      [error(diag.implementsDisallowedClass, 19, 3)],
    );
  }

  test_class_Null() async {
    await assertErrorsInCode(
      '''
class A implements Null {}
''',
      [error(diag.implementsDisallowedClass, 19, 4)],
    );
  }

  test_class_num() async {
    await assertErrorsInCode(
      '''
class A implements num {}
''',
      [error(diag.implementsDisallowedClass, 19, 3)],
    );
  }

  test_class_Record() async {
    await assertErrorsInCode(
      '''
class A implements Record {}
''',
      [error(diag.implementsDisallowedClass, 19, 6)],
    );
  }

  test_class_String() async {
    await assertErrorsInCode(
      '''
class A implements String {}
''',
      [error(diag.implementsDisallowedClass, 19, 6)],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_String_inAugmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
augment class A implements String {}
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, [
      error(diag.implementsDisallowedClass, 45, 6),
    ]);
  }

  test_class_String_num() async {
    await assertErrorsInCode(
      '''
class A implements String, num {}
''',
      [
        error(diag.implementsDisallowedClass, 19, 6),
        error(diag.implementsDisallowedClass, 27, 3),
      ],
    );
  }

  test_classTypeAlias_bool() async {
    await assertErrorsInCode(
      r'''
class A {}
class M {}
class C = A with M implements bool;
''',
      [error(diag.implementsDisallowedClass, 52, 4)],
    );
  }

  test_classTypeAlias_dartCoreEnum_abstract() async {
    await assertNoErrorsInCode('''
class M {}
abstract class A = Object with M implements Enum;
''');
  }

  test_classTypeAlias_dartCoreEnum_language216_abstract() async {
    await assertErrorsInCode(
      '''
// @dart = 2.16
mixin M {}
abstract class A = Object with M implements Enum;
''',
      [error(diag.implementsDisallowedClass, 71, 4)],
    );
  }

  test_classTypeAlias_dartCoreEnum_language216_concrete() async {
    await assertErrorsInCode(
      '''
// @dart = 2.16
mixin M {}
class A = Object with M implements Enum;
''',
      [error(diag.implementsDisallowedClass, 62, 4)],
    );
  }

  test_classTypeAlias_double() async {
    await assertErrorsInCode(
      r'''
class A {}
class M {}
class C = A with M implements double;
''',
      [error(diag.implementsDisallowedClass, 52, 6)],
    );
  }

  test_classTypeAlias_FutureOr() async {
    await assertErrorsInCode(
      r'''
import 'dart:async';
class A {}
class M {}
class C = A with M implements FutureOr;
''',
      [error(diag.implementsDisallowedClass, 73, 8)],
    );
  }

  test_classTypeAlias_int() async {
    await assertErrorsInCode(
      r'''
class A {}
class M {}
class C = A with M implements int;
''',
      [error(diag.implementsDisallowedClass, 52, 3)],
    );
  }

  test_classTypeAlias_Null() async {
    await assertErrorsInCode(
      r'''
class A {}
class M {}
class C = A with M implements Null;
''',
      [error(diag.implementsDisallowedClass, 52, 4)],
    );
  }

  test_classTypeAlias_num() async {
    await assertErrorsInCode(
      r'''
class A {}
class M {}
class C = A with M implements num;
''',
      [error(diag.implementsDisallowedClass, 52, 3)],
    );
  }

  test_classTypeAlias_String() async {
    await assertErrorsInCode(
      r'''
class A {}
class M {}
class C = A with M implements String;
''',
      [error(diag.implementsDisallowedClass, 52, 6)],
    );
  }

  test_classTypeAlias_String_num() async {
    await assertErrorsInCode(
      r'''
class A {}
class M {}
class C = A with M implements String, num;
''',
      [
        error(diag.implementsDisallowedClass, 52, 6),
        error(diag.implementsDisallowedClass, 60, 3),
      ],
    );
  }

  test_enum_int() async {
    await assertErrorsInCode(
      '''
enum E implements int {
  v
}
''',
      [error(diag.implementsDisallowedClass, 18, 3)],
    );
  }

  test_mixin_dartCoreEnum() async {
    await assertNoErrorsInCode('''
mixin M implements Enum {}
''');
  }

  test_mixin_dartCoreEnum_language216() async {
    await assertErrorsInCode(
      '''
// @dart = 2.16
mixin M implements Enum {}
''',
      [error(diag.implementsDisallowedClass, 35, 4)],
    );
  }

  test_mixin_int() async {
    await assertErrorsInCode(
      r'''
mixin M implements int {}
''',
      [error(diag.implementsDisallowedClass, 19, 3)],
    );

    var node = findNode.singleImplementsClause;
    assertResolvedNodeText(node, r'''
ImplementsClause
  implementsKeyword: implements
  interfaces
    NamedType
      name: int
      element: dart:core::@class::int
      type: int
''');
  }
}
