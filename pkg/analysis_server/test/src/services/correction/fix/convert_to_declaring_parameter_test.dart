// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToDeclaringParameterInClassBulkTest);
    defineReflectiveTests(ConvertToDeclaringParameterInClassTest);
    defineReflectiveTests(ConvertToDeclaringParameterInEnumBulkTest);
    defineReflectiveTests(ConvertToDeclaringParameterInEnumTest);
  });
}

@reflectiveTest
class ConvertToDeclaringParameterInClassBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.use_declaring_parameters;

  Future<void> test_multipleFields_multipleDeclarations() async {
    await resolveTestCode('''
class C(int x, int y) {
  int x;

  int y;

  this : x = x, y = y;
}
''');
    await assertHasFix('''
class C(var int x, int y) {
  int y;

  this : y = y;
}
''');
  }

  Future<void> test_multipleFields_singleDeclaration() async {
    await resolveTestCode('''
class C(int x, int y) {
  int x, y;

  this : x = x, y = y;
}
''');
    await assertHasFix('''
class C(var int x, int y) {
  int y;

  this : y = y;
}
''');
  }
}

@reflectiveTest
class ConvertToDeclaringParameterInClassTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.convertToDeclaringParameter;

  @override
  String get lintCode => LintNames.use_declaring_parameters;

  Future<void> test_body_withAnnotation() async {
    await resolveTestCode('''
class C(int x) {
  int x;

  @a
  this : x = x;
}

const a = 0;
''');
    await assertHasFix('''
class C(var int x) {
  @a
  this;
}

const a = 0;
''');
  }

  Future<void> test_body_withAnnotationAndComment() async {
    await resolveTestCode('''
class C(int x) {
  int x;

  /// A comment
  /// on multiple lines.
  @a
  this : x = x;
}

const a = 0;
''');
    await assertHasFix('''
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
class C(this.x) {
  int x;

  this {
    print(x);
  }
}
''');
    await assertHasFix('''
class C(var int x) {
  this {
    print(x);
  }
}
''');
  }

  Future<void> test_body_withBlockAndInitializer() async {
    await resolveTestCode('''
class C(int x) {
  int x;

  this : x = x {
    print(x);
  }
}
''');
    await assertHasFix('''
class C(var int x) {
  this {
    print(x);
  }
}
''');
  }

  Future<void> test_body_withDocComment() async {
    await resolveTestCode('''
class C(int x) {
  int x;

  /// A comment
  /// on multiple lines.
  this : x = x;
}
''');
    await assertHasFix('''
class C(var int x) {
  /// A comment
  /// on multiple lines.
  this;
}
''');
  }

  Future<void> test_body_withInitializer_simple() async {
    await resolveTestCode('''
class C(int x) {
  int x;

  this : x = x;
}
''');
    await assertHasFix('''
class C(var int x) {
}
''');
  }

  Future<void> test_body_withNormalComment_emptyBody() async {
    await resolveTestCode('''
class C(int x) {
  int x;

  // A comment
  this : x = x;
}
''');
    await assertHasFix('''
class C(var int x) {
}
''');
  }

  Future<void> test_body_withNormalComment_nonEmptyBody() async {
    await resolveTestCode('''
class C(int x) {
  int x;

  // A comment
  this : x = x {}
}
''');
    await assertHasFix('''
class C(var int x) {
  // A comment
  this {}
}
''');
  }

  Future<void> test_field_withDocComment() async {
    await resolveTestCode('''
class C(int x) {
  /// A comment
  /// on multiple lines.
  int x;

  this : x = x;
}
''');
    await assertHasFix('''
class C(
  /// A comment
  /// on multiple lines.
  var int x) {
}
''');
  }

  Future<void> test_optionalNamed_fieldFormalParameter_final() async {
    await resolveTestCode('''
class C({this.x = 0}) {
  final int x;
}
''');
    await assertHasFix('''
class C({final int x = 0}) {
}
''');
  }

  Future<void> test_optionalNamed_fieldFormalParameter_nonFinal() async {
    await resolveTestCode('''
class C({this.x = 0}) {
  int x;
}
''');
    await assertHasFix('''
class C({var int x = 0}) {
}
''');
  }

  Future<void> test_optionalNamed_simple_final() async {
    await resolveTestCode('''
class C({int x = 0}) {
  final int x;

  this : x = x;
}
''');
    await assertHasFix('''
class C({final int x = 0}) {
}
''');
  }

  Future<void> test_optionalNamed_simple_nonFinal() async {
    await resolveTestCode('''
class C({int x = 0}) {
  int x;

  this : x = x;
}
''');
    await assertHasFix('''
class C({var int x = 0}) {
}
''');
  }

  Future<void> test_optionalNamed_simple_nonFinal_privateField() async {
    await resolveTestCode('''
class C({int x = 0}) {
  int _x;

  this : _x = x;

  int get y => _x + 1;
}
''');
    await assertHasFix('''
class C({var int _x = 0}) {

  int get y => _x + 1;
}
''');
  }

  Future<void> test_optionalPositional_fieldFormalParameter_final() async {
    await resolveTestCode('''
class C([this.x = 0]) {
  final int x;
}
''');
    await assertHasFix('''
class C([final int x = 0]) {
}
''');
  }

  Future<void> test_optionalPositional_fieldFormalParameter_nonFinal() async {
    await resolveTestCode('''
class C([this.x = 0]) {
  int x;
}
''');
    await assertHasFix('''
class C([var int x = 0]) {
}
''');
  }

  Future<void> test_optionalPositional_simple_final() async {
    await resolveTestCode('''
class C([int x = 0]) {
  final int x;

  this : x = x;
}
''');
    await assertHasFix('''
class C([final int x = 0]) {
}
''');
  }

  Future<void> test_optionalPositional_simple_nonFinal() async {
    await resolveTestCode('''
class C([int x = 0]) {
  int x;

  this : x = x;
}
''');
    await assertHasFix('''
class C([var int x = 0]) {
}
''');
  }

  Future<void> test_privateField() async {
    await resolveTestCode('''
class C(int x) {
  int _x;

  this : _x = x;

  int get y => _x + 1;
}
''');
    await assertHasFix('''
class C(var int _x) {

  int get y => _x + 1;
}
''');
  }

  Future<void> test_privateField_referencedInInitializer() async {
    await resolveTestCode('''
class C({required int? i}) {
  final int? _i;
  final bool _b;

  this : _i = i, _b = i != null;

  num get use => (_i ?? 0) + (_b ? 1 : 0);
}
''');
    await assertHasFix('''
class C({required final int? _i}) {
  final bool _b;

  this : _b = _i != null;

  num get use => (_i ?? 0) + (_b ? 1 : 0);
}
''');
  }

  Future<void> test_requiredNamed_fieldFormalParameter_final() async {
    await resolveTestCode('''
class C({required this.x}) {
  final int x;
}
''');
    await assertHasFix('''
class C({required final int x}) {
}
''');
  }

  Future<void> test_requiredNamed_fieldFormalParameter_nonFinal() async {
    await resolveTestCode('''
class C({required this.x}) {
  int x;
}
''');
    await assertHasFix('''
class C({required var int x}) {
}
''');
  }

  Future<void> test_requiredNamed_simple_final() async {
    await resolveTestCode('''
class C({required int x}) {
  final int x;

  this : x = x;
}
''');
    await assertHasFix('''
class C({required final int x}) {
}
''');
  }

  Future<void> test_requiredNamed_simple_nonFinal() async {
    await resolveTestCode('''
class C({required int x}) {
  int x;

  this : x = x;
}
''');
    await assertHasFix('''
class C({required var int x}) {
}
''');
  }

  Future<void> test_requiredPositional_fieldFormalParameter_final() async {
    await resolveTestCode('''
class C(this.x) {
  final int x;
}
''');
    await assertHasFix('''
class C(final int x) {
}
''');
  }

  Future<void>
  test_requiredPositional_fieldFormalParameter_nonFinal_noType() async {
    await resolveTestCode('''
class C(this.x) {
  int x;
}
''');
    await assertHasFix('''
class C(var int x) {
}
''');
  }

  test_requiredPositional_fieldFormalParameter_nonFinal_sameType() async {
    await resolveTestCode(r'''
class C(int this.x) {
  int x;
}
''');
    await assertHasFix('''
class C(var int x) {
}
''');
  }

  Future<void> test_requiredPositional_simple_final() async {
    await resolveTestCode('''
class C(int x) {
  final int x;

  this : x = x;
}
''');
    await assertHasFix('''
class C(final int x) {
}
''');
  }

  Future<void> test_requiredPositional_simple_nonFinal() async {
    await resolveTestCode('''
class C(int x) {
  int x;

  this : x = x;
}
''');
    await assertHasFix('''
class C(var int x) {
}
''');
  }

  Future<void> test_requiredPositional_simple_nonFinal_explicitThis() async {
    await resolveTestCode('''
class C(int x) {
  int x;

  this : this.x = x;
}
''');
    await assertHasFix('''
class C(var int x) {
}
''');
  }

  Future<void> test_type_imported() async {
    await resolveTestCode('''
import 'dart:core' as core;

class C(core.int x) {
  final core.int x;

  this : x = x;
}
''');
    await assertHasFix('''
import 'dart:core' as core;

class C(final core.int x) {
}
''');
  }

  Future<void> test_type_typedef_both() async {
    await resolveTestCode('''
class C(T x) {
  final T x;

  this : x = x;
}
typedef T = int;
''');
    await assertHasFix('''
class C(final T x) {
}
typedef T = int;
''');
  }

  Future<void> test_type_typedef_field() async {
    await resolveTestCode('''
class C(int x) {
  final T x;

  this : x = x;
}
typedef T = int;
''');
    await assertHasFix('''
class C(final int x) {
}
typedef T = int;
''');
  }

  Future<void> test_type_typedef_param() async {
    await resolveTestCode('''
class C(T x) {
  final int x;

  this : x = x;
}
typedef T = int;
''');
    await assertHasFix('''
class C(final T x) {
}
typedef T = int;
''');
  }
}

@reflectiveTest
class ConvertToDeclaringParameterInEnumBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.use_declaring_parameters;

  Future<void> test_multipleFields_multipleDeclarations() async {
    await resolveTestCode('''
enum E(int x, int y) {
  a(0, 0);

  final int x;

  final int y;

  this : x = x, y = y;
}
''');
    await assertHasFix('''
enum E(final int x, int y) {
  a(0, 0);

  final int y;

  this : y = y;
}
''');
  }

  Future<void> test_multipleFields_singleDeclaration() async {
    await resolveTestCode('''
enum E(int x, int y) {
  a(0, 0);

  final int x, y;

  this : x = x, y = y;
}
''');
    await assertHasFix('''
enum E(final int x, int y) {
  a(0, 0);

  final int y;

  this : y = y;
}
''');
  }
}

@reflectiveTest
class ConvertToDeclaringParameterInEnumTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.convertToDeclaringParameter;

  @override
  String get lintCode => LintNames.use_declaring_parameters;

  Future<void> test_optionalNamed_fieldFormalParameter() async {
    await resolveTestCode('''
enum E({this.x = 0}) {
  a(x: 0);

  final int x;
}
''');
    await assertHasFix('''
enum E({final int x = 0}) {
  a(x: 0);

}
''');
  }

  Future<void> test_optionalNamed_simple() async {
    await resolveTestCode('''
enum E({int x = 0}) {
  a(x: 0);

  final int x;

  this : x = x;
}
''');
    await assertHasFix('''
enum E({final int x = 0}) {
  a(x: 0);

}
''');
  }

  Future<void> test_optionalNamed_simple_privateField() async {
    await resolveTestCode('''
enum E({int x = 0}) {
  a(x: 0);

  final int _x;

  this : _x = x;

  int get y => _x + 1;
}
''');
    await assertHasFix('''
enum E({final int _x = 0}) {
  a(x: 0);


  int get y => _x + 1;
}
''');
  }

  Future<void> test_optionalPositional_fieldFormalParameter() async {
    await resolveTestCode('''
enum E([this.x = 0]) {
  a(0);

  final int x;
}
''');
    await assertHasFix('''
enum E([final int x = 0]) {
  a(0);

}
''');
  }

  Future<void> test_optionalPositional_simple() async {
    await resolveTestCode('''
enum E([int x = 0]) {
  a(0);

  final int x;

  this : x = x;
}
''');
    // TODO(brianwilkerson): It would be nice to remove the extra blank line.
    await assertHasFix('''
enum E([final int x = 0]) {
  a(0);

}
''');
  }

  Future<void> test_privateField() async {
    await resolveTestCode('''
enum E(int x) {
  a(0);

  final int _x;

  this : _x = x;

  int get y => _x + 1;
}
''');
    await assertHasFix('''
enum E(final int _x) {
  a(0);


  int get y => _x + 1;
}
''');
  }

  Future<void> test_requiredNamed_fieldFormalParameter() async {
    await resolveTestCode('''
enum E({required this.x}) {
  a(x: 0);

  final int x;
}
''');
    await assertHasFix('''
enum E({required final int x}) {
  a(x: 0);

}
''');
  }

  Future<void> test_requiredNamed_simple() async {
    await resolveTestCode('''
enum E({required int x}) {
  a(x: 0);

  final int x;

  this : x = x;
}
''');
    await assertHasFix('''
enum E({required final int x}) {
  a(x: 0);

}
''');
  }

  Future<void> test_requiredPositional_fieldFormalParameter() async {
    await resolveTestCode('''
enum E(this.x) {
  a(0);

  final int x;
}
''');
    await assertHasFix('''
enum E(final int x) {
  a(0);

}
''');
  }

  Future<void> test_requiredPositional_simple() async {
    await resolveTestCode('''
enum E(int x) {
  a(0);

  final int x;

  this : x = x;
}
''');
    await assertHasFix('''
enum E(final int x) {
  a(0);

}
''');
  }

  Future<void> test_requiredPositional_simple_explicitThis() async {
    await resolveTestCode('''
enum E(int x) {
  a(0);

  final int x;

  this : this.x = x;
}
''');
    await assertHasFix('''
enum E(final int x) {
  a(0);

}
''');
  }

  Future<void> test_withInitializer_simple() async {
    await resolveTestCode('''
enum E(int x) {
  a(0);

  final int x;

  this : x = x;
}
''');
    await assertHasFix('''
enum E(final int x) {
  a(0);

}
''');
  }
}
