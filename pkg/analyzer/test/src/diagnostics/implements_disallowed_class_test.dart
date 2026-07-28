// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplementsDisallowedClassTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ImplementsDisallowedClassTest extends PubPackageResolutionTest {
  test_class_bool() async {
    await resolveTestCodeWithDiagnostics(r'''
class A implements bool {}
//                 ^^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'bool'.
''');
  }

  test_class_dartCoreEnum_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A implements Enum {}
''');
  }

  test_class_dartCoreEnum_language216_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.16
abstract class A implements Enum {}
//                          ^^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'Enum'.
''');
  }

  test_class_dartCoreEnum_language216_concrete() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.16
class A implements Enum {}
//                 ^^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'Enum'.
''');
  }

  test_class_double() async {
    await resolveTestCodeWithDiagnostics(r'''
class A implements double {}
//                 ^^^^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'double'.
''');
  }

  test_class_FutureOr() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
class A implements FutureOr {}
//                 ^^^^^^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'FutureOr<dynamic>'.
''');
  }

  test_class_FutureOr_typeArgument() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
class A implements FutureOr<int> {}
//                 ^^^^^^^^^^^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'FutureOr<int>'.
''');
  }

  test_class_FutureOr_typedef() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
typedef F = FutureOr<void>;
class A implements F {}
//                 ^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'F'.
''');
  }

  test_class_FutureOr_typeVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
class A<T> implements FutureOr<T> {}
//                    ^^^^^^^^^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'FutureOr<T>'.
''');
  }

  test_class_int() async {
    await resolveTestCodeWithDiagnostics(r'''
class A implements int {}
//                 ^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'int'.
''');
  }

  test_class_Null() async {
    await resolveTestCodeWithDiagnostics(r'''
class A implements Null {}
//                 ^^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'Null'.
''');
  }

  test_class_num() async {
    await resolveTestCodeWithDiagnostics(r'''
class A implements num {}
//                 ^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'num'.
''');
  }

  test_class_Record() async {
    await resolveTestCodeWithDiagnostics(r'''
class A implements Record {}
//                 ^^^^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'Record'.
''');
  }

  test_class_String() async {
    await resolveTestCodeWithDiagnostics(r'''
class A implements String {}
//                 ^^^^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'String'.
''');
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_class_String_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
augment class A implements String {}
''');
  }

  test_class_String_num() async {
    await resolveTestCodeWithDiagnostics(r'''
class A implements String, num {}
//                 ^^^^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'String'.
//                         ^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'num'.
''');
  }

  test_classTypeAlias_bool() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class M {}
class C = A with M implements bool;
//                            ^^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'bool'.
''');
  }

  test_classTypeAlias_dartCoreEnum_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
class M {}
abstract class A = Object with M implements Enum;
''');
  }

  test_classTypeAlias_dartCoreEnum_language216_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.16
mixin M {}
abstract class A = Object with M implements Enum;
//                                          ^^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'Enum'.
''');
  }

  test_classTypeAlias_dartCoreEnum_language216_concrete() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.16
mixin M {}
class A = Object with M implements Enum;
//                                 ^^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'Enum'.
''');
  }

  test_classTypeAlias_double() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class M {}
class C = A with M implements double;
//                            ^^^^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'double'.
''');
  }

  test_classTypeAlias_FutureOr() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
class A {}
class M {}
class C = A with M implements FutureOr;
//                            ^^^^^^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'FutureOr<dynamic>'.
''');
  }

  test_classTypeAlias_int() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class M {}
class C = A with M implements int;
//                            ^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'int'.
''');
  }

  test_classTypeAlias_Null() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class M {}
class C = A with M implements Null;
//                            ^^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'Null'.
''');
  }

  test_classTypeAlias_num() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class M {}
class C = A with M implements num;
//                            ^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'num'.
''');
  }

  test_classTypeAlias_String() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class M {}
class C = A with M implements String;
//                            ^^^^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'String'.
''');
  }

  test_classTypeAlias_String_num() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class M {}
class C = A with M implements String, num;
//                            ^^^^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'String'.
//                                    ^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'num'.
''');
  }

  test_enum_int() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E implements int {
//                ^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'int'.
  v
}
''');
  }

  test_mixin_dartCoreEnum() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M implements Enum {}
''');
  }

  test_mixin_dartCoreEnum_language216() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.16
mixin M implements Enum {}
//                 ^^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'Enum'.
''');
  }

  test_mixin_int() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin M implements int {}
//                 ^^^
// [diag.implementsDisallowedClass] Classes and mixins can't implement 'int'.
''');

    var node = result.findNode.singleImplementsClause;
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
