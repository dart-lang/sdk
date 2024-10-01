// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EncapsulateFieldTest);
  });
}

@reflectiveTest
class EncapsulateFieldTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.ENCAPSULATE_FIELD;

  Future<void> test_alreadyPrivate() async {
    await resolveTestCode('''
class A {
  int _test = 42;
}
void f(A a) {
  print(a._test);
}
''');
    await assertNoAssistAt('_test =');
  }

  Future<void> test_annotations_deprecated2() async {
    await resolveTestCode('''
class A {
  @deprecated
  @deprecated
  int foo = 0;
}
''');
    await assertHasAssistAt('foo = 0', '''
class A {
  int _foo = 0;

  @deprecated
  @deprecated
  int get foo => _foo;

  @deprecated
  @deprecated
  set foo(int value) {
    _foo = value;
  }
}
''');
  }

  Future<void> test_annotations_overrides_deprecated2() async {
    await resolveTestCode('''
abstract class A {
  int get foo;
}

class B extends A {
  @deprecated
  @override
  @deprecated
  int foo = 0;
}
''');
    await assertHasAssistAt('foo = 0', '''
abstract class A {
  int get foo;
}

class B extends A {
  int _foo = 0;

  @deprecated
  @override
  @deprecated
  int get foo => _foo;

  @deprecated
  @deprecated
  set foo(int value) {
    _foo = value;
  }
}
''');
  }

  Future<void> test_annotations_overrides_deprecated2_sameLine() async {
    await resolveTestCode('''
abstract class A {
  int get foo;
}

class B extends A {
  @deprecated @override @deprecated
  int foo = 0;
}
''');
    await assertHasAssistAt('foo = 0', '''
abstract class A {
  int get foo;
}

class B extends A {
  int _foo = 0;

  @deprecated
  @override
  @deprecated
  int get foo => _foo;

  @deprecated
  @deprecated
  set foo(int value) {
    _foo = value;
  }
}
''');
  }

  Future<void> test_annotations_overrides_getter() async {
    await resolveTestCode('''
abstract class A {
  int get foo;
}

class B extends A {
  @override
  int foo = 0;
}
''');
    await assertHasAssistAt('foo = 0', '''
abstract class A {
  int get foo;
}

class B extends A {
  int _foo = 0;

  @override
  int get foo => _foo;

  set foo(int value) {
    _foo = value;
  }
}
''');
  }

  Future<void> test_annotations_overrides_getter_setter() async {
    await resolveTestCode('''
abstract class A {
  int get foo;
  set foo(int value);
}

class B extends A {
  @override
  int foo = 0;
}
''');
    await assertHasAssistAt('foo = 0', '''
abstract class A {
  int get foo;
  set foo(int value);
}

class B extends A {
  int _foo = 0;

  @override
  int get foo => _foo;

  @override
  set foo(int value) {
    _foo = value;
  }
}
''');
  }

  Future<void> test_annotations_overrides_setter() async {
    await resolveTestCode('''
abstract class A {
  set foo(int value);
}

class B extends A {
  @override
  int foo = 0;
}
''');
    await assertHasAssistAt('foo = 0', '''
abstract class A {
  set foo(int value);
}

class B extends A {
  int _foo = 0;

  int get foo => _foo;

  @override
  set foo(int value) {
    _foo = value;
  }
}
''');
  }

  Future<void> test_annotations_unresolved() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
abstract class A {
  int get foo;
}

class B extends A {
  @unresolved
  int foo = 0;
}
''');
    await assertHasAssistAt('foo = 0', '''
abstract class A {
  int get foo;
}

class B extends A {
  int _foo = 0;

  @unresolved
  int get foo => _foo;

  @unresolved
  set foo(int value) {
    _foo = value;
  }
}
''');
  }

  Future<void> test_documentation() async {
    await resolveTestCode('''
class A {
  /// AAA
  /// BBB
  int test = 0;
}
''');
    await assertHasAssistAt('test', '''
class A {
  /// AAA
  /// BBB
  int _test = 0;

  /// AAA
  /// BBB
  int get test => _test;

  /// AAA
  /// BBB
  set test(int value) {
    _test = value;
  }
}
''');
  }

  Future<void> test_enum_hasType() async {
    await resolveTestCode('''
enum E {
  v;
  final int test = 42;
}
''');
    // Enums can have only final fields, and final fields cannot be encapsulated
    // right now.
    await assertNoAssistAt('test = 42');
  }

  Future<void> test_extension_hasType() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
extension E on int {
  int test = 42;
}
''');
    await assertNoAssistAt('test = 42');
  }

  Future<void> test_final() async {
    await resolveTestCode('''
class A {
  final int test = 42;
}
''');
    await assertNoAssistAt('test =');
  }

  Future<void> test_hasType() async {
    await resolveTestCode('''
class A {
  int test = 42;
  A(this.test);
}
void f(A a) {
  print(a.test);
}
''');
    await assertHasAssistAt('test = 42', '''
class A {
  int _test = 42;

  int get test => _test;

  set test(int value) {
    _test = value;
  }
  A(this._test);
}
void f(A a) {
  print(a.test);
}
''');
  }

  Future<void> test_mixin_hasType() async {
    await resolveTestCode('''
mixin M {
  int test = 42;
}
''');
    await assertHasAssistAt('test = 42', '''
mixin M {
  int _test = 42;

  int get test => _test;

  set test(int value) {
    _test = value;
  }
}
''');
  }

  Future<void> test_multipleFields() async {
    await resolveTestCode('''
class A {
  int aaa = 0, bbb = 0, ccc = 0;
}
void f(A a) {
  print(a.bbb);
}
''');
    await assertNoAssistAt('bbb ');
  }

  Future<void> test_named() async {
    await resolveTestCode('''
class A {
  int? field;
  A({int? field}) : field = field;
}
''');
    await assertHasAssistAt('field', '''
class A {
  int? _field;

  int? get field => _field;

  set field(int? value) {
    _field = value;
  }
  A({int? field}) : _field = field;
}
''');
  }

  Future<void> test_named_formalParameter() async {
    await resolveTestCode('''
class A {
  int? field;
  A({this.field});
}
''');
    await assertHasAssistAt('field', '''
class A {
  int? _field;

  int? get field => _field;

  set field(int? value) {
    _field = value;
  }
  A({int? field}) : _field = field;
}
''');
  }

  Future<void> test_named_formalParameter_noType() async {
    await resolveTestCode('''
class C {
  var foo;

  C({required this.foo});
}
''');
    await assertHasAssistAt('foo;', '''
class C {
  var _foo;

  get foo => _foo;

  set foo(value) {
    _foo = value;
  }

  C({required foo}) : _foo = foo;
}
''');
  }

  Future<void> test_named_formalParameter_prefixedType() async {
    await resolveTestCode('''
import 'dart:math' as math;

class C {
  math.Random foo;

  C({required this.foo});
}
''');
    await assertHasAssistAt('foo;', '''
import 'dart:math' as math;

class C {
  math.Random _foo;

  math.Random get foo => _foo;

  set foo(math.Random value) {
    _foo = value;
  }

  C({required math.Random foo}) : _foo = foo;
}
''');
  }

  Future<void> test_named_super_initializer() async {
    await resolveTestCode('''
class A {}
class B extends A {
  int? field;
  B({this.field}) : super();
}
''');
    await assertHasAssistAt('field', '''
class A {}
class B extends A {
  int? _field;

  int? get field => _field;

  set field(int? value) {
    _field = value;
  }
  B({int? field}) : _field = field, super();
}
''');
  }

  Future<void> test_notOnName() async {
    await resolveTestCode('''
class A {
  int test = 1 + 2 + 3;
}
''');
    await assertNoAssistAt('+ 2');
  }

  Future<void> test_noType() async {
    await resolveTestCode('''
class A {
  var test = 42;
}
void f(A a) {
  print(a.test);
}
''');
    await assertHasAssistAt('test = 42', '''
class A {
  var _test = 42;

  get test => _test;

  set test(value) {
    _test = value;
  }
}
void f(A a) {
  print(a.test);
}
''');
  }

  Future<void> test_parseError() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
class A {
  int; // marker
}
void f(A a) {
  print(a.test);
}
''');
    await assertNoAssistAt('; // marker');
  }

  Future<void> test_positional() async {
    await resolveTestCode('''
class A {
  int? field;
  A([this.field]);
}
''');
    await assertHasAssistAt('field', '''
class A {
  int? _field;

  int? get field => _field;

  set field(int? value) {
    _field = value;
  }
  A([this._field]);
}
''');
  }

  Future<void> test_static() async {
    await resolveTestCode('''
class A {
  static int test = 42;
}
''');
    await assertNoAssistAt('test =');
  }
}
