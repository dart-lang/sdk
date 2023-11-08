// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveUnreachableFromMainTest);
    defineReflectiveTests(RemoveUnusedElementTest);
  });
}

@reflectiveTest
class RemoveUnreachableFromMainTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNUSED_ELEMENT;

  @override
  String get lintCode => LintNames.unreachable_from_main;

  Future<void> test_class() async {
    await resolveTestCode(r'''
void main() {}
class C {}
''');
    await assertHasFix(r'''
void main() {}
''');
  }

  Future<void> test_method() async {
    await resolveTestCode(r'''
void main() {
  C();
}
class C {
  void m() {}
}
''');
    await assertHasFix(r'''
void main() {
  C();
}
class C {
}
''');
  }
}

@reflectiveTest
class RemoveUnusedElementTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNUSED_ELEMENT;

  Future<void> test_class_constructor_first() async {
    await resolveTestCode(r'''
class A {
  A._named();

  A();
}
''');
    await assertHasFix(r'''
class A {
  A();
}
''');
  }

  Future<void> test_class_constructor_last() async {
    await resolveTestCode(r'''
class A {
  A();

  A._named();
}
''');
    await assertHasFix(r'''
class A {
  A();
}
''');
  }

  Future<void> test_class_constructor_middle() async {
    await resolveTestCode(r'''
class A {
  A();

  A._named();

  void foo() {}
}
''');
    await assertHasFix(r'''
class A {
  A();

  void foo() {}
}
''');
  }

  Future<void> test_class_notUsed_inClassMember() async {
    await resolveTestCode(r'''
class _A {
  staticMethod() {
    new _A();
  }
}
''');
    // TODO(pq): consider supporting the case where references are limited to
    //  within the class.
    await assertNoFix();
  }

  Future<void> test_class_notUsed_isExpression() async {
    await resolveTestCode(r'''
class _A {}
void f(p) {
  if (p is _A) {}
}
''');
    // We don't know what to do  with the reference.
    await assertNoFix();
  }

  Future<void> test_class_notUsed_noReference() async {
    await resolveTestCode(r'''
class _A {}
''');
    await assertHasFix(r'''
''');
  }

  Future<void> test_enum_constructor_first() async {
    await resolveTestCode(r'''
enum E {
  v;
  const E._named();
  const E();
}
''');
    await assertHasFix(r'''
enum E {
  v;
  const E();
}
''');
  }

  Future<void> test_enum_constructor_last() async {
    await resolveTestCode(r'''
enum E {
  v;
  const E();
  const E._named();
}
''');
    await assertHasFix(r'''
enum E {
  v;
  const E();
}
''');
  }

  Future<void> test_enum_notUsed_noReference() async {
    await resolveTestCode(r'''
enum _MyEnum {A, B, C}
''');
    await assertHasFix(r'''
''', errorFilter: (AnalysisError error) {
      return error.errorCode == WarningCode.UNUSED_ELEMENT;
    });
  }

  Future<void> test_functionLocal_notUsed_noReference() async {
    await resolveTestCode(r'''
void f() {
  f() {}
}
''');
    await assertHasFix(r'''
void f() {
}
''');
  }

  Future<void> test_functionTop_notUsed_noReference() async {
    await resolveTestCode(r'''
_f() {}
void f() {}
''');
    await assertHasFix(r'''
void f() {}
''');
  }

  Future<void> test_functionTypeAlias_notUsed_noReference() async {
    await resolveTestCode(r'''
typedef _F(a, b);
void f() {}
''');
    await assertHasFix(r'''
void f() {}
''');
  }

  Future<void> test_getter_notUsed_noReference() async {
    await resolveTestCode(r'''
class A {
  get _g => null;
}
''');
    await assertHasFix(r'''
class A {
}
''');
  }

  Future<void> test_method_notUsed_noReference() async {
    await resolveTestCode(r'''
class A {
  static _m() {}
}
''');
    await assertHasFix(r'''
class A {
}
''');
  }

  Future<void> test_setter_notUsed_noReference() async {
    await resolveTestCode(r'''
class A {
  set _s(x) {}
}
''');
    await assertHasFix(r'''
class A {
}
''');
  }

  Future<void> test_staticMethod_extension_notUsed_noReference() async {
    await resolveTestCode(r'''
extension _E on String {
  static int m1() => 3;
  int m2() => 7;
}
void f() => print(_E("hello").m2());
''');
    await assertHasFix(r'''
extension _E on String {
  int m2() => 7;
}
void f() => print(_E("hello").m2());
''');
  }

  Future<void> test_staticMethod_mixin_notUsed_noReference() async {
    await resolveTestCode(r'''
mixin _M {
  static int m1() => 3;
}
class C with _M {}
void f(C c) {}
''');
    await assertHasFix(r'''
mixin _M {
}
class C with _M {}
void f(C c) {}
''');
  }

  Future<void> test_staticMethod_notUsed_noReference() async {
    await resolveTestCode(r'''
class _A {
  static int m() => 7;
}
void f(_A a) {}
''');
    await assertHasFix(r'''
class _A {
}
void f(_A a) {}
''');
  }

  Future<void> test_topLevelVariable_notUsed() async {
    await resolveTestCode(r'''
int _a = 1;
void f() {
  _a = 2;
}
''');
    // Reference.
    await assertNoFix();
  }

  Future<void> test_topLevelVariable_notUsed_noReference_first() async {
    await resolveTestCode(r'''
int _a = 1, b = 2;
''');
    await assertHasFix(r'''
int b = 2;
''');
  }

  Future<void> test_topLevelVariable_notUsed_noReference_last() async {
    await resolveTestCode(r'''
int a = 1, _b = 2;
''');
    await assertHasFix(r'''
int a = 1;
''');
  }

  Future<void> test_topLevelVariable_notUsed_noReference_only() async {
    await resolveTestCode(r'''
int _a = 1;
void f() {}
''');
    await assertHasFix(r'''
void f() {}
''');
  }
}
