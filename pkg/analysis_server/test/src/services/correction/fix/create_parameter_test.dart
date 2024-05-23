// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateParameterTest);
  });
}

@reflectiveTest
class CreateParameterTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CREATE_PARAMETER;

  Future<void> test_dynamic_type() async {
    await resolveTestCode('''
int f(
  int b,
) {
  var i = b2;
  return i;
}
''');
    await assertHasFix('''
int f(
  int b,
  dynamic b2,
) {
  var i = b2;
  return i;
}
''');
  }

  Future<void> test_final_comma() async {
    await resolveTestCode('''
int f(
  int b,
) {
  int i = b2;
  return i;
}
''');
    await assertHasFix('''
int f(
  int b,
  int b2,
) {
  int i = b2;
  return i;
}
''');
  }

  Future<void> test_method_type() async {
    await resolveTestCode('''
class A{
  int f(
    int b,
  ) {
    int i = b2;
    return i;
  }
}
''');
    await assertHasFix('''
class A{
  int f(
    int b,
    int b2,
  ) {
    int i = b2;
    return i;
  }
}
''');
  }

  Future<void> test_multi() async {
    await resolveTestCode('''
int f(int b) {
  int i = b2;
  return i;
}
''');
    await assertHasFix('''
int f(int b, int b2) {
  int i = b2;
  return i;
}
''');
  }

  Future<void> test_only() async {
    await resolveTestCode('''
int f() {
  int i = b;
  return i;
}
''');
    await assertHasFix('''
int f(int b) {
  int i = b;
  return i;
}
''');
  }

  Future<void> test_with_constructor() async {
    await resolveTestCode('''
class A {
  A() {
    int i = b;
    g(i);
  }
}
void g(int n) {}
''');
    await assertHasFix('''
class A {
  A(int b) {
    int i = b;
    g(i);
  }
}
void g(int n) {}
''');
  }

  Future<void> test_with_local_function() async {
    await resolveTestCode('''
void f(int a) {
  int g(int a){
    int i = b2;
    return i;
  }
  g(3);
}
''');
    await assertHasFix('''
void f(int a) {
  int g(int a, int b2){
    int i = b2;
    return i;
  }
  g(3);
}
''');
  }

  Future<void> test_with_named() async {
    await resolveTestCode('''
int f({int? b}) {
  int i = b2;
  return i;
}
''');
    await assertHasFix('''
int f({int? b, required int b2}) {
  int i = b2;
  return i;
}
''');
  }

  Future<void> test_with_named_and_positional() async {
    await resolveTestCode('''
int f(int a, {int? b}) {
  int i = b2;
  return i;
}
''');
    await assertHasFix('''
int f(int a, int b2, {int? b}) {
  int i = b2;
  return i;
}
''');
  }

  Future<void> test_with_named_nullable() async {
    await resolveTestCode('''
int? f({int? b}) {
  int? i = b2;
  return i;
}
''');
    await assertHasFix('''
int? f({int? b, int? b2}) {
  int? i = b2;
  return i;
}
''');
  }

  Future<void> test_with_optional_positional() async {
    await resolveTestCode('''
int f([int? b]) {
  int i = b2;
  return i;
}
''');
    await assertHasFix('''
int f(int b2, [int? b]) {
  int i = b2;
  return i;
}
''');
  }

  Future<void> test_with_required_positional_and_optional() async {
    await resolveTestCode('''
int f(int a, [int? b]) {
  int i = b2;
  return i;
}
''');
    await assertHasFix('''
int f(int a, int b2, [int? b]) {
  int i = b2;
  return i;
}
''');
  }

  Future<void> test_with_required_positional_and_optional_trailing() async {
    await resolveTestCode('''
int f(
  int a, [
  int? b,
]) {
  int i = b2;
  return i;
}
''');
    await assertHasFix('''
int f(
  int a,
  int b2, [
  int? b,
]) {
  int i = b2;
  return i;
}
''');
  }
}
