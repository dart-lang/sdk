// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToDeclaringParameterInClassTest);
    defineReflectiveTests(ConvertToDeclaringParameterInEnumTest);
  });
}

@reflectiveTest
class ConvertToDeclaringParameterInClassTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertToDeclaringParameter;

  Future<void> test_body_withAnnotation() async {
    await resolveTestCode('''
class C(int x^) {
  int x;

  @a
  this : x = x;
}

const a = 0;
''');
    await assertHasAssist('''
class C(var int x) {
  @a
  this;
}

const a = 0;
''');
  }

  Future<void> test_body_withAnnotationAndComment() async {
    await resolveTestCode('''
class C(int x^) {
  int x;

  /// A comment
  /// on multiple lines.
  @a
  this : x = x;
}

const a = 0;
''');
    await assertHasAssist('''
class C(var int x) {
  /// A comment
  /// on multiple lines.
  @a
  this;
}

const a = 0;
''');
  }

  Future<void> test_body_withBlock() async {
    await resolveTestCode('''
class C(this.x^) {
  int x;

  this {
    print(x);
  }
}
''');
    await assertHasAssist('''
class C(var int x) {
  this {
    print(x);
  }
}
''');
  }

  Future<void> test_body_withBlockAndInitializer() async {
    await resolveTestCode('''
class C(int x^) {
  int x;

  this : x = x {
    print(x);
  }
}
''');
    await assertHasAssist('''
class C(var int x) {
  this {
    print(x);
  }
}
''');
  }

  Future<void> test_body_withDocComment() async {
    await resolveTestCode('''
class C(int x^) {
  int x;

  /// A comment
  /// on multiple lines.
  this : x = x;
}
''');
    await assertHasAssist('''
class C(var int x) {
  /// A comment
  /// on multiple lines.
  this;
}
''');
  }

  Future<void> test_body_withInitializer_complex() async {
    await resolveTestCode('''
class C(int x^) {
  int x;

  this : x = x + 1;
}
''');
    await assertNoAssist();
  }

  Future<void> test_body_withInitializer_simple() async {
    await resolveTestCode('''
class C(int x^) {
  int x;

  this : x = x;
}
''');
    await assertHasAssist('''
class C(var int x) {
}
''');
  }

  Future<void> test_body_withNormalComment_emptyBody() async {
    await resolveTestCode('''
class C(int x^) {
  int x;

  // A comment
  this : x = x;
}
''');
    await assertHasAssist('''
class C(var int x) {
}
''');
  }

  Future<void> test_body_withNormalComment_nonEmptyBody() async {
    await resolveTestCode('''
class C(int x^) {
  int x;

  // A comment
  this : x = x {}
}
''');
    await assertHasAssist('''
class C(var int x) {
  // A comment
  this {}
}
''');
  }

  Future<void> test_first() async {
    await resolveTestCode('''
class C(int x^, int y) {
  int x;

  int y;

  this : x = x, y = y;
}
''');
    await assertHasAssist('''
class C(var int x, int y) {
  int y;

  this : y = y;
}
''');
  }

  Future<void> test_last() async {
    await resolveTestCode('''
class C(int x, int y^) {
  int x;

  int y;

  this : x = x, y = y;
}
''');
    await assertHasAssist('''
class C(int x, var int y) {
  int x;

  this : x = x;
}
''');
  }

  Future<void> test_middle() async {
    await resolveTestCode('''
class C(int x, int y^, int z) {
  int x;

  int y;

  int z;

  this : x = x, y = y, z = z;
}
''');
    await assertHasAssist('''
class C(int x, var int y, int z) {
  int x;

  int z;

  this : x = x, z = z;
}
''');
  }

  Future<void> test_optionalNamed_fieldFormalParameter_final() async {
    await resolveTestCode('''
class C({this.x^ = 0}) {
  final int x;
}
''');
    await assertHasAssist('''
class C({final int x = 0}) {
}
''');
  }

  Future<void> test_optionalNamed_fieldFormalParameter_nonFinal() async {
    await resolveTestCode('''
class C({this.x^ = 0}) {
  int x;
}
''');
    await assertHasAssist('''
class C({var int x = 0}) {
}
''');
  }

  Future<void> test_optionalNamed_simple_final() async {
    await resolveTestCode('''
class C({int x^ = 0}) {
  final int x;

  this : x = x;
}
''');
    await assertHasAssist('''
class C({final int x = 0}) {
}
''');
  }

  Future<void> test_optionalNamed_simple_nonFinal() async {
    await resolveTestCode('''
class C({int x^ = 0}) {
  int x;

  this : x = x;
}
''');
    await assertHasAssist('''
class C({var int x = 0}) {
}
''');
  }

  Future<void> test_optionalNamed_simple_nonFinal_privateField() async {
    await resolveTestCode('''
class C({int x^ = 0}) {
  int _x;

  this : _x = x;
}
''');
    await assertHasAssist('''
class C({var int _x = 0}) {
}
''');
  }

  Future<void> test_optionalNamed_super() async {
    await resolveTestCode('''
class C({super.x^ = 0}) extends B {
}

class B {
  B({required int x});
}
''');
    await assertNoAssist();
  }

  Future<void> test_optionalPositional_fieldFormalParameter_final() async {
    await resolveTestCode('''
class C([this.x^ = 0]) {
  final int x;
}
''');
    await assertHasAssist('''
class C([final int x = 0]) {
}
''');
  }

  Future<void> test_optionalPositional_fieldFormalParameter_nonFinal() async {
    await resolveTestCode('''
class C([this.x^ = 0]) {
  int x;
}
''');
    await assertHasAssist('''
class C([var int x = 0]) {
}
''');
  }

  Future<void> test_optionalPositional_simple_final() async {
    await resolveTestCode('''
class C([int x^ = 0]) {
  final int x;

  this : x = x;
}
''');
    await assertHasAssist('''
class C([final int x = 0]) {
}
''');
  }

  Future<void> test_optionalPositional_simple_nonFinal() async {
    await resolveTestCode('''
class C([int x^ = 0]) {
  int x;

  this : x = x;
}
''');
    await assertHasAssist('''
class C([var int x = 0]) {
}
''');
  }

  Future<void> test_optionalPositional_super() async {
    await resolveTestCode('''
class C([super.x^ = 0]) extends B {
}

class B {
  B(int x);
}
''');
    await assertNoAssist();
  }

  Future<void> test_privateField() async {
    await resolveTestCode('''
class C(int x^) {
  int _x;

  this : _x = x;
}
''');
    await assertHasAssist('''
class C(var int _x) {
}
''');
  }

  Future<void> test_requiredNamed_fieldFormalParameter_final() async {
    await resolveTestCode('''
class C({required this.x^}) {
  final int x;
}
''');
    await assertHasAssist('''
class C({required final int x}) {
}
''');
  }

  Future<void> test_requiredNamed_fieldFormalParameter_nonFinal() async {
    await resolveTestCode('''
class C({required this.x^}) {
  int x;
}
''');
    await assertHasAssist('''
class C({required var int x}) {
}
''');
  }

  Future<void> test_requiredNamed_simple_final() async {
    await resolveTestCode('''
class C({required int x^}) {
  final int x;

  this : x = x;
}
''');
    await assertHasAssist('''
class C({required final int x}) {
}
''');
  }

  Future<void> test_requiredNamed_simple_nonFinal() async {
    await resolveTestCode('''
class C({required int x^}) {
  int x;

  this : x = x;
}
''');
    await assertHasAssist('''
class C({required var int x}) {
}
''');
  }

  Future<void> test_requiredNamed_super() async {
    await resolveTestCode('''
class C({required super.x^}) extends B {
}

class B {
  B({required int x});
}
''');
    await assertNoAssist();
  }

  Future<void> test_requiredPositional_fieldFormalParameter_final() async {
    await resolveTestCode('''
class C(this.x^) {
  final int x;
}
''');
    await assertHasAssist('''
class C(final int x) {
}
''');
  }

  Future<void> test_requiredPositional_fieldFormalParameter_nonFinal() async {
    await resolveTestCode('''
class C(this.x^) {
  int x;
}
''');
    await assertHasAssist('''
class C(var int x) {
}
''');
  }

  Future<void> test_requiredPositional_simple_abstractField() async {
    await resolveTestCode('''
abstract class C(int x^) {
  abstract int x;
}
''');
    await assertNoAssist();
  }

  Future<void> test_requiredPositional_simple_externalField() async {
    await resolveTestCode('''
class C(int x^) {
  external int x;
}
''');
    await assertNoAssist();
  }

  Future<void> test_requiredPositional_simple_final() async {
    await resolveTestCode('''
class C(int x^) {
  final int x;

  this : x = x;
}
''');
    await assertHasAssist('''
class C(final int x) {
}
''');
  }

  Future<void> test_requiredPositional_simple_lateField() async {
    await resolveTestCode('''
class C(int x^) {
  late int x;
}
''');
    await assertNoAssist();
  }

  Future<void> test_requiredPositional_simple_nonFinal() async {
    await resolveTestCode('''
class C(int x^) {
  int x;

  this : x = x;
}
''');
    await assertHasAssist('''
class C(var int x) {
}
''');
  }

  Future<void> test_requiredPositional_simple_nonFinal_explicitThis() async {
    await resolveTestCode('''
class C(int x^) {
  int x;

  this : this.x = x;
}
''');
    await assertHasAssist('''
class C(var int x) {
}
''');
  }

  Future<void>
  test_requiredPositional_simple_nonFinal_multipleFieldsInOneDeclaration() async {
    await resolveTestCode('''
class C(int x^, int y) {
  int x, y;

  this : x = x, y = y;
}
''');
    await assertHasAssist('''
class C(var int x, int y) {
  int y;

  this : y = y;
}
''');
  }

  Future<void> test_requiredPositional_simple_nonFinal_narrowerField() async {
    await resolveTestCode('''
class C(num x^) {
  int x;

  this : x = x.toInt();
}
''');
    await assertNoAssist();
  }

  Future<void> test_requiredPositional_simple_nonFinal_widerField() async {
    await resolveTestCode('''
class C(int x^) {
  num x;

  this : x = x;
}
''');
    await assertNoAssist();
  }

  Future<void> test_requiredPositional_simple_staticField() async {
    await resolveTestCode('''
class C(int x^) {
  static int x = 0;
}
''');
    await assertNoAssist();
  }

  Future<void> test_requiredPositional_super() async {
    await resolveTestCode('''
class C(super.x^) extends B {
}

class B {
  B(int x);
}
''');
    await assertNoAssist();
  }

  Future<void> test_type_functionTyped() async {
    await resolveTestCode('''
class C(int x^(String s)) {
  final int Function(String s) x;

  this : x = x;
}
''');
    await assertNoAssist();
  }

  Future<void> test_type_imported() async {
    await resolveTestCode('''
import 'dart:core' as core;

class C(core.int x^) {
  final core.int x;

  this : x = x;
}
''');
    await assertHasAssist('''
import 'dart:core' as core;

class C(final core.int x) {
}
''');
  }

  Future<void> test_type_typedef_both() async {
    await resolveTestCode('''
class C(T x^) {
  final T x;

  this : x = x;
}
typedef T = int;
''');
    await assertHasAssist('''
class C(final T x) {
}
typedef T = int;
''');
  }

  Future<void> test_type_typedef_field() async {
    await resolveTestCode('''
class C(int x^) {
  final T x;

  this : x = x;
}
typedef T = int;
''');
    await assertHasAssist('''
class C(final int x) {
}
typedef T = int;
''');
  }

  Future<void> test_type_typedef_param() async {
    await resolveTestCode('''
class C(T x^) {
  final int x;

  this : x = x;
}
typedef T = int;
''');
    await assertHasAssist('''
class C(final T x) {
}
typedef T = int;
''');
  }

  Future<void> test_withAnnotations_onField() async {
    await resolveTestCode('''
class C(int x^) {
  @a
  @b
  int x;

  this : x = x;
}

const a = 0;
const b = 1;
''');
    await assertNoAssist();
    // TODO(brianwilkerson): Do we want to support this case? Doing so would add
    //  the annotation to the parameter, which might not be what the user wants.
    //     await assertHasAssist('''
    // class C(
    //   @a
    //   @b
    //   var int x) {
    // }

    // const a = 0;
    // const b = 1;
    // ''');
  }

  Future<void> test_withAnnotations_onFieldAndParam() async {
    await resolveTestCode('''
class C(
  @a
  @b
  int x^) {
  @c
  @d
  int x;

  this : x = x;
}

const a = 0;
const b = 1;
const c = 2;
const d = 3;
''');
    await assertNoAssist();
    // TODO(brianwilkerson): Do we want to support this case? Doing so would add
    //  the annotation to the parameter, which might not be what the user wants.
    //     await assertHasAssist('''
    // class C(
    //   @a
    //   @b
    //   @c
    //   @d
    //   var int x) {
    // }

    // const a = 0;
    // const b = 1;
    // const c = 2;
    // const d = 3;
    // ''');
  }

  Future<void> test_withAnnotations_onParam() async {
    await resolveTestCode('''
class C(
  @a
  @b
  int x^) {
  int x;

  this : x = x;
}

const a = 0;
const b = 1;
''');
    await assertNoAssist();
    // TODO(brianwilkerson): Do we want to support this case? Doing so would add
    //  the annotation to the parameter, which might not be what the user wants.
    //     await assertHasAssist('''
    // class C(
    //   @a
    //   @b
    //   var int x) {
    // }

    // const a = 0;
    // const b = 1;
    // ''');
  }

  Future<void> test_withDocComment() async {
    await resolveTestCode('''
class C(int x^) {
  /// A comment
  /// on multiple lines.
  int x;

  this : x = x;
}
''');
    await assertNoAssist();
  }

  Future<void> test_withDocCommentAndAnnotations() async {
    await resolveTestCode('''
class C(int x^) {
  /// A comment
  /// on multiple lines.
  @a
  @b
  int x;

  this : x = x;
}

const a = 0;
const b = 1;
''');
    await assertNoAssist();
  }
}

@reflectiveTest
class ConvertToDeclaringParameterInEnumTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertToDeclaringParameter;

  Future<void> test_first() async {
    await resolveTestCode('''
enum E(int x^, int y) {
  a(0, 0);

  final int x;

  final int y;

  this : x = x, y = y;
}
''');
    await assertHasAssist('''
enum E(final int x, int y) {
  a(0, 0);

  final int y;

  this : y = y;
}
''');
  }

  Future<void> test_last() async {
    await resolveTestCode('''
enum E(int x, int y^) {
  a(0, 0);

  final int x;

  final int y;

  this : x = x, y = y;
}
''');
    await assertHasAssist('''
enum E(int x, final int y) {
  a(0, 0);

  final int x;

  this : x = x;
}
''');
  }

  Future<void> test_middle() async {
    await resolveTestCode('''
enum E(int x, int y^, int z) {
  a(0, 0, 0);

  final int x;

  final int y;

  final int z;

  this : x = x, y = y, z = z;
}
''');
    await assertHasAssist('''
enum E(int x, final int y, int z) {
  a(0, 0, 0);

  final int x;

  final int z;

  this : x = x, z = z;
}
''');
  }

  Future<void> test_optionalNamed_fieldFormalParameter() async {
    await resolveTestCode('''
enum E({this.x^ = 0}) {
  a(x: 0);

  final int x;
}
''');
    await assertHasAssist('''
enum E({final int x = 0}) {
  a(x: 0);

}
''');
  }

  Future<void> test_optionalNamed_simple() async {
    await resolveTestCode('''
enum E({int x^ = 0}) {
  a(x: 0);

  final int x;

  this : x = x;
}
''');
    await assertHasAssist('''
enum E({final int x = 0}) {
  a(x: 0);

}
''');
  }

  Future<void> test_optionalNamed_simple_privateField() async {
    await resolveTestCode('''
enum E({int x^ = 0}) {
  a(x: 0);

  final int _x;

  this : _x = x;
}
''');
    await assertHasAssist('''
enum E({final int _x = 0}) {
  a(x: 0);

}
''');
  }

  Future<void> test_optionalPositional_fieldFormalParameter() async {
    await resolveTestCode('''
enum E([this.x^ = 0]) {
  a(0);

  final int x;
}
''');
    await assertHasAssist('''
enum E([final int x = 0]) {
  a(0);

}
''');
  }

  Future<void> test_optionalPositional_simple() async {
    await resolveTestCode('''
enum E([int x^ = 0]) {
  a(0);

  final int x;

  this : x = x;
}
''');
    // TODO(brianwilkerson): It would be nice to remove the extra blank line.
    await assertHasAssist('''
enum E([final int x = 0]) {
  a(0);

}
''');
  }

  Future<void> test_privateField() async {
    await resolveTestCode('''
enum E(int x^) {
  a(0);

  final int _x;

  this : _x = x;
}
''');
    await assertHasAssist('''
enum E(final int _x) {
  a(0);

}
''');
  }

  Future<void> test_requiredNamed_fieldFormalParameter() async {
    await resolveTestCode('''
enum E({required this.x^}) {
  a(x: 0);

  final int x;
}
''');
    await assertHasAssist('''
enum E({required final int x}) {
  a(x: 0);

}
''');
  }

  Future<void> test_requiredNamed_simple() async {
    await resolveTestCode('''
enum E({required int x^}) {
  a(x: 0);

  final int x;

  this : x = x;
}
''');
    await assertHasAssist('''
enum E({required final int x}) {
  a(x: 0);

}
''');
  }

  Future<void> test_requiredPositional_fieldFormalParameter() async {
    await resolveTestCode('''
enum E(this.x^) {
  a(0);

  final int x;
}
''');
    await assertHasAssist('''
enum E(final int x) {
  a(0);

}
''');
  }

  Future<void> test_requiredPositional_simple() async {
    await resolveTestCode('''
enum E(int x^) {
  a(0);

  final int x;

  this : x = x;
}
''');
    await assertHasAssist('''
enum E(final int x) {
  a(0);

}
''');
  }

  Future<void> test_requiredPositional_simple_explicitThis() async {
    await resolveTestCode('''
enum E(int x^) {
  a(0);

  final int x;

  this : this.x = x;
}
''');
    await assertHasAssist('''
enum E(final int x) {
  a(0);

}
''');
  }

  Future<void>
  test_requiredPositional_simple_multipleFieldsInOneDeclaration() async {
    await resolveTestCode('''
enum E(int x^, int y) {
  a(0, 0);

  final int x, y;

  this : x = x, y = y;
}
''');
    await assertHasAssist('''
enum E(final int x, int y) {
  a(0, 0);

  final int y;

  this : y = y;
}
''');
  }

  Future<void> test_requiredPositional_simple_narrowerField() async {
    await resolveTestCode('''
enum E(num x^) {
  a(0);

  final int x;

  this : x = x as int;
}
''');
    await assertNoAssist();
  }

  Future<void> test_requiredPositional_simple_staticField() async {
    await resolveTestCode('''
enum E(int x^) {
  a(0);

  static int x = 0;
}
''');
    await assertNoAssist();
  }

  Future<void> test_requiredPositional_simple_widerField() async {
    await resolveTestCode('''
enum E(int x^) {
  a(0);

  final num x;

  this : x = x;
}
''');
    await assertNoAssist();
  }

  Future<void> test_withAnnotations_onField() async {
    await resolveTestCode('''
enum E(int x^) {
  e(0);

  @a
  @b
  final int x;

  this : x = x;
}

const a = 0;
const b = 1;
''');
    await assertNoAssist();
    // TODO(brianwilkerson): Do we want to support this case? Doing so would add
    //  the annotation to the parameter, which might not be what the user wants.
    //     await assertHasAssist('''
    // enum E(
    //   @a
    //   @b
    //   final int x) {
    //   e(0);

    // }

    // const a = 0;
    // const b = 1;
    // ''');
  }

  Future<void> test_withDocComment() async {
    await resolveTestCode('''
enum E(int x^) {
  a(0);

  /// A comment
  /// on multiple lines.
  final int x;

  this : x = x;
}
''');
    await assertNoAssist();
  }

  Future<void> test_withDocCommentAndAnnotations() async {
    await resolveTestCode('''
enum E(int x^) {
  a(0);

  /// A comment
  /// on multiple lines.
  @a
  @b
  final int x;

  this : x = x;
}

const a = 0;
const b = 1;
''');
    await assertNoAssist();
  }

  Future<void> test_withInitializer_complex() async {
    await resolveTestCode('''
enum E(int x^) {
  a(0);

  final int x;

  this : x = x + 1;
}
''');
    await assertNoAssist();
  }

  Future<void> test_withInitializer_simple() async {
    await resolveTestCode('''
enum E(int x^) {
  a(0);

  final int x;

  this : x = x;
}
''');
    await assertHasAssist('''
enum E(final int x) {
  a(0);

}
''');
  }
}
