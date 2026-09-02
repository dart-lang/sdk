// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtendsDisallowedClassTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ExtendsDisallowedClassTest extends PubPackageResolutionTest {
  test_class_bool() async {
    await resolveTestCodeWithDiagnostics(r'''
class A extends bool {}
//              ^^^^
// [diag.extendsDisallowedClass] Classes can't extend 'bool'.
''');
  }

  test_class_double() async {
    await resolveTestCodeWithDiagnostics(r'''
class A extends double {}
//              ^^^^^^
// [diag.extendsDisallowedClass] Classes can't extend 'double'.
''');
  }

  test_class_FutureOr() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
class A extends FutureOr {}
//              ^^^^^^^^
// [diag.extendsDisallowedClass] Classes can't extend 'FutureOr<dynamic>'.
''');
  }

  test_class_FutureOr_typeArgument() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
class A extends FutureOr<int> {}
//              ^^^^^^^^^^^^^
// [diag.extendsDisallowedClass] Classes can't extend 'FutureOr<int>'.
''');
  }

  test_class_FutureOr_typedef() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
typedef F = FutureOr<void>;
class A extends F {}
//              ^
// [diag.extendsDisallowedClass] Classes can't extend 'F'.
''');
  }

  test_class_FutureOr_typeVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
class A<T> extends FutureOr<T> {}
//                 ^^^^^^^^^^^
// [diag.extendsDisallowedClass] Classes can't extend 'FutureOr<T>'.
''');
  }

  test_class_int() async {
    await resolveTestCodeWithDiagnostics(r'''
class A extends int {}
//              ^^^
// [diag.extendsDisallowedClass] Classes can't extend 'int'.
''');
  }

  test_class_Null() async {
    await resolveTestCodeWithDiagnostics(r'''
class A extends Null {}
//              ^^^^
// [diag.extendsDisallowedClass] Classes can't extend 'Null'.
''');
  }

  test_class_num() async {
    await resolveTestCodeWithDiagnostics(r'''
class A extends num {}
//              ^^^
// [diag.extendsDisallowedClass] Classes can't extend 'num'.
''');
  }

  test_class_Record() async {
    await resolveTestCodeWithDiagnostics(r'''
class A extends Record {}
//              ^^^^^^
// [diag.extendsDisallowedClass] Classes can't extend 'Record'.
''');
  }

  test_class_String() async {
    await resolveTestCodeWithDiagnostics(r'''
class A extends String {}
//              ^^^^^^
// [diag.extendsDisallowedClass] Classes can't extend 'String'.
''');
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_class_String_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
augment class A extends String {}
''');
  }

  test_classTypeAlias_bool() async {
    await resolveTestCodeWithDiagnostics(r'''
class M {}
class C = bool with M;
//        ^^^^
// [diag.extendsDisallowedClass] Classes can't extend 'bool'.
''');
  }

  test_classTypeAlias_double() async {
    await resolveTestCodeWithDiagnostics(r'''
class M {}
class C = double with M;
//        ^^^^^^
// [diag.extendsDisallowedClass] Classes can't extend 'double'.
''');
  }

  test_classTypeAlias_FutureOr() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
class M {}
class C = FutureOr with M;
//        ^^^^^^^^
// [diag.extendsDisallowedClass] Classes can't extend 'FutureOr<dynamic>'.
''');
  }

  test_classTypeAlias_int() async {
    await resolveTestCodeWithDiagnostics(r'''
class M {}
class C = int with M;
//        ^^^
// [diag.extendsDisallowedClass] Classes can't extend 'int'.
''');
  }

  test_classTypeAlias_Null() async {
    await resolveTestCodeWithDiagnostics(r'''
class M {}
class C = Null with M;
//        ^^^^
// [diag.extendsDisallowedClass] Classes can't extend 'Null'.
''');
  }

  test_classTypeAlias_num() async {
    await resolveTestCodeWithDiagnostics(r'''
class M {}
class C = num with M;
//        ^^^
// [diag.extendsDisallowedClass] Classes can't extend 'num'.
''');
  }

  test_classTypeAlias_String() async {
    await resolveTestCodeWithDiagnostics(r'''
class M {}
class C = String with M;
//        ^^^^^^
// [diag.extendsDisallowedClass] Classes can't extend 'String'.
''');
  }
}
