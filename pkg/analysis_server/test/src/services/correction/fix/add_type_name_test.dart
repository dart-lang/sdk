// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddTypeNameBulkTest);
    defineReflectiveTests(AddTypeNameInFileTest);
    defineReflectiveTests(AddTypeNameTest);
  });
}

@reflectiveTest
class AddTypeNameBulkTest extends BulkFixProcessorTest {
  Future<void> test_bulk() async {
    await resolveTestCode('''
// @dart = 3.9

enum E {a}

E foo(E e) {
  foo(.a);
  return .a;
}
''');
    await assertHasFix('''
// @dart = 3.9

enum E {a}

E foo(E e) {
  foo(E.a);
  return E.a;
}
''');
  }
}

@reflectiveTest
class AddTypeNameInFileTest extends FixInFileProcessorTest {
  Future<void> test_file() async {
    await resolveTestCode(r'''
// @dart = 3.9

enum E {a}

E foo(E e) {
  foo(.a);
  return .a;
}
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, r'''
// @dart = 3.9

enum E {a}

E foo(E e) {
  foo(E.a);
  return E.a;
}
''');
  }
}

@reflectiveTest
class AddTypeNameTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.addTypeName;

  Future<void> test_experimentNotEnabled() async {
    await resolveTestCode('''
// @dart = 3.9

enum E {a}

void foo(E e) => foo(.a);
''');
    await assertHasFix('''
// @dart = 3.9

enum E {a}

void foo(E e) => foo(E.a);
''');
  }

  Future<void> test_functionType() async {
    await resolveTestCode('''
// @dart = 3.9

// ignore: dot_shorthand_undefined_member
void f(int Function(int) g) => f(.m());
''');
    await assertNoFix();
  }

  Future<void> test_record() async {
    await resolveTestCode('''
// @dart = 3.9

// ignore: dot_shorthand_undefined_member
void f((int,) g) => f(.m());
''');
    await assertNoFix();
  }

  Future<void> test_typeParameter() async {
    await resolveTestCode('''
// @dart = 3.9

class C {}
// ignore: dot_shorthand_undefined_member
void f<T extends C>(T g) => f(.m());
''');
    await assertNoFix();
  }

  Future<void> test_withTypeParameter() async {
    await resolveTestCode('''
// @dart = 3.9

class C<T> {
  C.m();
}
void f(C<int> c) => f(.m());
''');
    await assertHasFix('''
// @dart = 3.9

class C<T> {
  C.m();
}
void f(C<int> c) => f(C.m());
''');
  }
}
