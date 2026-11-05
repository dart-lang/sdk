// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinOfDisallowedClassTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MixinOfDisallowedClassTest extends PubPackageResolutionTest {
  test_class_bool() async {
    await resolveTestCodeWithDiagnostics('''
class A extends Object with bool {}
//                          ^^^^
// [diag.mixinOfDisallowedClass] Classes can't mixin 'bool'.
''');
  }

  test_class_bool_augment() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

augment class A with bool {}
//                   ^^^^
// [diag.mixinOfDisallowedClass] Classes can't mixin 'bool'.
''');
  }

  test_class_double() async {
    await resolveTestCodeWithDiagnostics('''
class A extends Object with double {}
//                          ^^^^^^
// [diag.mixinOfDisallowedClass] Classes can't mixin 'double'.
''');
  }

  test_class_FutureOr() async {
    await resolveTestCodeWithDiagnostics('''
import 'dart:async';
class A extends Object with FutureOr {}
//                          ^^^^^^^^
// [diag.mixinOfDisallowedClass] Classes can't mixin 'FutureOr<dynamic>'.
''');
  }

  test_class_FutureOr_typeArgument() async {
    await resolveTestCodeWithDiagnostics('''
import 'dart:async';
class A extends Object with FutureOr<int> {}
//                          ^^^^^^^^^^^^^
// [diag.mixinOfDisallowedClass] Classes can't mixin 'FutureOr<int>'.
''');
  }

  test_class_FutureOr_typeVariable() async {
    await resolveTestCodeWithDiagnostics('''
import 'dart:async';
class A<T> extends Object with FutureOr<T> {}
//                             ^^^^^^^^^^^
// [diag.mixinOfDisallowedClass] Classes can't mixin 'FutureOr<T>'.
''');
  }

  test_class_int() async {
    await resolveTestCodeWithDiagnostics('''
class A extends Object with int {}
//                          ^^^
// [diag.mixinOfDisallowedClass] Classes can't mixin 'int'.
''');
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_class_int_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
augment class A with int {}
''');
  }

  test_class_Null() async {
    await resolveTestCodeWithDiagnostics('''
class A extends Object with Null {}
//                          ^^^^
// [diag.mixinOfDisallowedClass] Classes can't mixin 'Null'.
''');
  }

  test_class_num() async {
    await resolveTestCodeWithDiagnostics('''
class A extends Object with num {}
//                          ^^^
// [diag.mixinOfDisallowedClass] Classes can't mixin 'num'.
''');
  }

  test_class_Record() async {
    await resolveTestCodeWithDiagnostics('''
class A extends Object with Record {}
//                          ^^^^^^
// [diag.mixinOfDisallowedClass] Classes can't mixin 'Record'.
''');
  }

  test_class_String() async {
    await resolveTestCodeWithDiagnostics('''
class A extends Object with String {}
//                          ^^^^^^
// [diag.mixinOfDisallowedClass] Classes can't mixin 'String'.
''');
  }

  test_classTypeAlias_bool() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class C = A with bool;
//               ^^^^
// [diag.mixinOfDisallowedClass] Classes can't mixin 'bool'.
''');
  }

  test_classTypeAlias_double() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class C = A with double;
//               ^^^^^^
// [diag.mixinOfDisallowedClass] Classes can't mixin 'double'.
''');
  }

  test_classTypeAlias_FutureOr() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
class A {}
class C = A with FutureOr;
//               ^^^^^^^^
// [diag.mixinOfDisallowedClass] Classes can't mixin 'FutureOr<dynamic>'.
''');
  }

  test_classTypeAlias_int() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class C = A with int;
//               ^^^
// [diag.mixinOfDisallowedClass] Classes can't mixin 'int'.
''');
  }

  test_classTypeAlias_Null() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class C = A with Null;
//               ^^^^
// [diag.mixinOfDisallowedClass] Classes can't mixin 'Null'.
''');
  }

  test_classTypeAlias_num() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class C = A with num;
//               ^^^
// [diag.mixinOfDisallowedClass] Classes can't mixin 'num'.
''');
  }

  test_classTypeAlias_String() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class C = A with String;
//               ^^^^^^
// [diag.mixinOfDisallowedClass] Classes can't mixin 'String'.
''');
  }

  test_classTypeAlias_String_num() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class C = A with String, num;
//               ^^^^^^
// [diag.mixinOfDisallowedClass] Classes can't mixin 'String'.
//                       ^^^
// [diag.mixinOfDisallowedClass] Classes can't mixin 'num'.
''');
  }

  test_enum_int() async {
    await resolveTestCodeWithDiagnostics('''
enum E with int {
//          ^^^
// [diag.mixinOfDisallowedClass] Classes can't mixin 'int'.
  v
}
''');
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_enum_int_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
enum A {v}
augment enum A with int {}
''');
  }
}
