// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveConstConstConstructorParamTypeMismatchTest);
    defineReflectiveTests(RemoveConstNonConstantListElementTest);
    defineReflectiveTests(RemoveConstNonConstantMapElementTest);
    defineReflectiveTests(RemoveConstNonConstantMapKeyTest);
    defineReflectiveTests(RemoveConstNonConstantMapValueTest);
    defineReflectiveTests(RemoveConstNonConstantSetElementTest);
    defineReflectiveTests(RemoveConstTest);
  });
}

@reflectiveTest
class RemoveConstConstConstructorParamTypeMismatchTest
    extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_CONST;

  Future<void> test_named() async {
    await resolveTestCode(r'''
class A {
  const A(String s);
}
class C {
  const C({A? a});
}
void f(int i) {
  const C(a: A('$i'));
}
''');
    await assertHasFix(r'''
class A {
  const A(String s);
}
class C {
  const C({A? a});
}
void f(int i) {
  C(a: A('$i'));
}
''');
  }

  Future<void> test_not_assignable_type() async {
    await resolveTestCode(r'''
class A {
  const A(String s);
}
class C {
  const C({A? a});
}
void f(int i) {
  const C(a: A(3));
}
''');
    await assertNoFix(
      errorFilter:
          (error) =>
              error.errorCode ==
              CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
    );
  }

  Future<void> test_recursive() async {
    await resolveTestCode(r'''
class A {
  const A(String s);
}
class C {
  const C(A a, A a2);
}
void f(int i) {
  const C(A('$i'), A(''));
}
''');
    await assertHasFix(r'''
class A {
  const A(String s);
}
class C {
  const C(A a, A a2);
}
void f(int i) {
  C(A('$i'), const A(''));
}
''');
  }
}

@reflectiveTest
class RemoveConstNonConstantListElementTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_CONST;

  Future<void> test_expressionStatement() async {
    await resolveTestCode(r'''
class A {
  const A();
}
void f(int i) {
  const [A(), 'i = $i'];
}
''');
    await assertHasFix(r'''
class A {
  const A();
}
void f(int i) {
  [const A(), 'i = $i'];
}
''');
  }

  Future<void> test_fromDeferredLibrary() async {
    newFile('$testPackageLibPath/a.dart', '''
const int c = 1;
''');
    await resolveTestCode(r'''
import 'a.dart' deferred as a;
var v = const [a.c];
''');
    await assertHasFix(r'''
import 'a.dart' deferred as a;
var v = [a.c];
''');
  }

  Future<void> test_grandChild() async {
    await resolveTestCode(r'''
class A {
  const A();
}
Object f(int i) {
  return const [A(), 'i = $i'];
}
''');
    await assertHasFix(r'''
class A {
  const A();
}
Object f(int i) {
  return [const A(), 'i = $i'];
}
''');
  }

  Future<void> test_instanceCreation_noConstant() async {
    await resolveTestCode(r'''
class A {
  const A();
}
class B {}
var v = const [A(), B()];
''');
    await assertHasFix(
      r'''
class A {
  const A();
}
class B {}
var v = [const A(), B()];
''',
      // TODO(FMorschel): CONST_WITH_NON_CONST should not be probably triggered
      errorFilter:
          (error) =>
              error.errorCode == CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT,
    );
  }

  Future<void> test_recursive_alternating() async {
    await resolveTestCode(r'''
class A {
  const A();
}
class B {}
Object f() {
  return const [A(), /*0*/B(), [A(), /*1*/B()]];
}
''');
    await assertHasFix(
      r'''
class A {
  const A();
}
class B {}
Object f() {
  return [const A(), B(), [const A(), B()]];
}
''',
      errorFilter:
          (error) =>
              error.offset == parsedTestCode.positions[0].offset &&
              error.errorCode == CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT,
    );
    await assertHasFix(
      r'''
class A {
  const A();
}
class B {}
Object f() {
  return [const A(), B(), [const A(), B()]];
}
''',
      errorFilter:
          (error) =>
              error.offset == parsedTestCode.positions[1].offset &&
              error.errorCode == CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT,
    );
  }

  Future<void> test_recursive_equal() async {
    await resolveTestCode(r'''
class A {
  const A();
}
class B {}
Object f() {
  return const [A(), ^B(), [A(), A()]];
}
''');
    await assertHasFix(
      r'''
class A {
  const A();
}
class B {}
Object f() {
  return [const A(), B(), const [A(), A()]];
}
''',
      errorFilter:
          (error) =>
              error.offset == parsedTestCode.position.offset &&
              error.errorCode == CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT,
    );
  }

  Future<void> test_variableDeclaration() async {
    await resolveTestCode(r'''
class A {
  const A();
  A.nonConst();
}
const x = [A(), A.nonConst()];
''');
    await assertHasFix(
      r'''
class A {
  const A();
  A.nonConst();
}
final x = [const A(), A.nonConst()];
''',
      // TODO(FMorschel): CONST_WITH_NON_CONST and
      // CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE should not be triggered and
      // NON_CONSTANT_LIST_ELEMENT should have the position for the element
      errorFilter:
          (error) =>
              error.errorCode == CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT,
    );
  }
}

@reflectiveTest
class RemoveConstNonConstantMapElementTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_CONST;

  Future<void> test_expressionStatement() async {
    await resolveTestCode(r'''
class A {
  const A();
}
void f() {
  var notConst = {};
  const {1: null, 2: A(), ...notConst};
}
''');
    await assertHasFix(r'''
class A {
  const A();
}
void f() {
  var notConst = {};
  {1: null, 2: const A(), ...notConst};
}
''');
  }

  Future<void> test_fromDeferredLibrary() async {
    newFile('$testPackageLibPath/a.dart', '''
const m = {};
''');
    await resolveTestCode(r'''
import 'a.dart' deferred as a;
var v = const {1: null, 2: 1, ...a.m};
''');
    await assertHasFix(r'''
import 'a.dart' deferred as a;
var v = {1: null, 2: 1, ...a.m};
''');
  }

  Future<void> test_spreadElement() async {
    await resolveTestCode(r'''
class A {
  const A();
}
var notConst = {};
var v = const {1: null, 2: A(), ...notConst};
''');
    await assertHasFix(r'''
class A {
  const A();
}
var notConst = {};
var v = {1: null, 2: const A(), ...notConst};
''');
  }
}

@reflectiveTest
class RemoveConstNonConstantMapKeyTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_CONST;

  Future<void> test_fromDeferredLibrary() async {
    newFile('$testPackageLibPath/a.dart', '''
const int c = 1;
''');
    await resolveTestCode(r'''
import 'a.dart' deferred as a;
const cond = true;
var v = const { if (cond) a.c : 0};
''');
    await assertHasFix(r'''
import 'a.dart' deferred as a;
const cond = true;
var v = { if (cond) a.c : 0};
''');
  }

  Future<void> test_ifElement() async {
    await resolveTestCode(r'''
Object f(dynamic a) {
  return const {if (1 < 0) a: 0};
}
''');
    await assertHasFix(r'''
Object f(dynamic a) {
  return {if (1 < 0) a: 0};
}
''');
  }
}

@reflectiveTest
class RemoveConstNonConstantMapValueTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_CONST;

  Future<void> test_fromDeferredLibrary() async {
    newFile('$testPackageLibPath/a.dart', '''
const int c = 1;
''');
    await resolveTestCode(r'''
import 'a.dart' deferred as a;
var v = const {'a' : a.c};
''');
    await assertHasFix(r'''
import 'a.dart' deferred as a;
var v = {'a' : a.c};
''');
  }

  Future<void> test_grandChild() async {
    await resolveTestCode(r'''
class A {
  const A();
}
Object f(int i) {
  return const {A(): A(), 2: 'i = $i'};
}
''');
    await assertHasFix(r'''
class A {
  const A();
}
Object f(int i) {
  return {const A(): const A(), 2: 'i = $i'};
}
''');
  }

  Future<void> test_instanceCreation_noConstant() async {
    await resolveTestCode(r'''
class A {
  const A();
}
class B {}
var v = const {1: A(), 2: B()};
''');
    await assertHasFix(
      r'''
class A {
  const A();
}
class B {}
var v = {1: const A(), 2: B()};
''',
      // TODO(FMorschel): CONST_WITH_NON_CONST should not be probably triggered
      errorFilter:
          (error) =>
              error.errorCode == CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE,
    );
  }

  Future<void> test_variableDeclaration() async {
    await resolveTestCode(r'''
class A {
  const A();
  A.nonConst();
}
const v = {1: A(), 2: A.nonConst()};
''');
    await assertHasFix(
      r'''
class A {
  const A();
  A.nonConst();
}
final v = {1: const A(), 2: A.nonConst()};
''',
      // TODO(FMorschel): CONST_WITH_NON_CONST should not be probably triggered
      errorFilter:
          (error) =>
              error.errorCode == CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE,
    );
  }
}

@reflectiveTest
class RemoveConstNonConstantSetElementTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_CONST;

  Future<void> test_fromDeferredLibrary() async {
    newFile('$testPackageLibPath/a.dart', '''
const int c = 1;
''');
    await resolveTestCode(r'''
import 'a.dart' deferred as a;
const cond = true;
var v = const {if (cond) a.c};
''');
    await assertHasFix(r'''
import 'a.dart' deferred as a;
const cond = true;
var v = {if (cond) a.c};
''');
  }

  Future<void> test_grandChild() async {
    await resolveTestCode(r'''
class A {
  const A();
}
Object f(int i) {
  return const {A(), 'i = $i'};
}
''');
    await assertHasFix(r'''
class A {
  const A();
}
Object f(int i) {
  return {const A(), 'i = $i'};
}
''');
  }

  Future<void> test_instanceCreation_noConstant() async {
    await resolveTestCode(r'''
class A {
  const A();
}
class B {}
var v = const {A(), B()};
''');
    await assertHasFix(
      r'''
class A {
  const A();
}
class B {}
var v = {const A(), B()};
''',
      // TODO(FMorschel): CONST_WITH_NON_CONST should not be probably triggered
      errorFilter:
          (error) =>
              error.errorCode == CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT,
    );
  }

  Future<void> test_variableDeclaration() async {
    await resolveTestCode(r'''
class A {
  const A();
  A.nonConst();
}
const v = {A(), A.nonConst()};
''');
    await assertHasFix(
      r'''
class A {
  const A();
  A.nonConst();
}
final v = {const A(), A.nonConst()};
''',
      // TODO(FMorschel): CONST_WITH_NON_CONST should not be probably triggered
      errorFilter:
          (error) =>
              error.errorCode == CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT,
    );
  }
}

@reflectiveTest
class RemoveConstTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_CONST;

  Future<void> test_constClass_firstClass() async {
    await resolveTestCode('''
const class C {}
''');
    await assertHasFix('''
class C {}
''');
  }

  Future<void> test_constClass_secondClass() async {
    await resolveTestCode('''
class A {}
const class B {}
''');
    await assertHasFix('''
class A {}
class B {}
''');
  }

  Future<void> test_constClass_withComment() async {
    await resolveTestCode('''
/// Comment.
const class C {}
''');
    await assertHasFix('''
/// Comment.
class C {}
''');
  }

  Future<void> test_constFactoryConstructor() async {
    await resolveTestCode('''
class C {
  C._();
  const factory C() => C._();
}
''');
    await assertHasFix('''
class C {
  C._();
  factory C() => C._();
}
''');
  }

  Future<void> test_constInitializedWithNonConstantValue() async {
    await resolveTestCode('''
var x = 0;
const y = x;
''');
    await assertHasFix('''
var x = 0;
final y = x;
''');
  }

  Future<void> test_explicitConst() async {
    await resolveTestCode('''
class A {
  A(_);
}
var x = const A([0]);
''');
    await assertHasFix('''
class A {
  A(_);
}
var x = A([0]);
''');
  }

  Future<void> test_implicitConst_instanceCreation_argument() async {
    await resolveTestCode('''
class A {}

class B {
  const B(a, b);
}

var x = const B(A(), [0]);
''');
    await assertHasFix('''
class A {}

class B {
  const B(a, b);
}

var x = B(A(), const [0]);
''');
  }

  Future<void> test_implicitConst_instanceCreation_argument_named() async {
    await resolveTestCode('''
class A {}

class B {
  const B({a1, b, a2});
}

var x = const B(a1: A(), b: [0], a2: A());
''');
    await assertHasFix(
      '''
class A {}

class B {
  const B({a1, b, a2});
}

var x = B(a1: A(), b: const [0], a2: A());
''',
      errorFilter: (e) {
        return e.errorCode == CompileTimeErrorCode.CONST_WITH_NON_CONST &&
            e.offset == testCode.indexOf('A()');
      },
    );
  }

  Future<void> test_implicitConst_invalidConstant() async {
    await resolveTestCode('''
class A {
  const A(_, _);
}

void f(bool b) {
  const A(b ? 0 : 1, [2]);
}
''');
    await assertHasFix('''
class A {
  const A(_, _);
}

void f(bool b) {
  A(b ? 0 : 1, const [2]);
}
''');
  }

  Future<void> test_implicitConst_listLiteral_sibling_ifElement() async {
    await resolveTestCode('''
class A {}

var x = const [A(), if (true) [0] else [1]];
''');
    await assertHasFix(
      '''
class A {}

var x = [A(), if (true) const [0] else const [1]];
''',
      errorFilter: (e) {
        return e.errorCode == CompileTimeErrorCode.CONST_WITH_NON_CONST;
      },
    );
  }

  Future<void> test_implicitConst_listLiteral_sibling_instanceCreation() async {
    await resolveTestCode('''
class A {}

class B {
  const B();
}

var x = const [A(), const B(), B(), A()];
''');
    await assertHasFix(
      '''
class A {}

class B {
  const B();
}

var x = [A(), const B(), const B(), A()];
''',
      errorFilter: (e) {
        return e.errorCode == CompileTimeErrorCode.CONST_WITH_NON_CONST &&
            e.offset == testCode.indexOf('A()');
      },
    );
  }

  Future<void> test_implicitConst_listLiteral_sibling_listLiteral() async {
    await resolveTestCode('''
class A {}

var x = const [A(), const [0], [1]];
''');
    await assertHasFix(
      '''
class A {}

var x = [A(), const [0], const [1]];
''',
      errorFilter: (e) {
        return e.errorCode == CompileTimeErrorCode.CONST_WITH_NON_CONST;
      },
    );
  }

  Future<void>
  test_implicitConst_listLiteral_sibling_spreadElement_list() async {
    await resolveTestCode('''
class A {}

var x = const [A(), ...const [0], ...[1]];
''');
    await assertHasFix(
      '''
class A {}

var x = [A(), ...const [0], ...const [1]];
''',
      errorFilter: (e) {
        return e.errorCode == CompileTimeErrorCode.CONST_WITH_NON_CONST;
      },
    );
  }

  Future<void> test_implicitConst_mapLiteral() async {
    await resolveTestCode('''
class A {}

var x = const {0: A(), ...const {1: 2}, ...{3: 4}};
''');
    await assertHasFix(
      '''
class A {}

var x = {0: A(), ...const {1: 2}, ...const {3: 4}};
''',
      errorFilter: (e) {
        return e.errorCode == CompileTimeErrorCode.CONST_WITH_NON_CONST;
      },
    );
  }

  Future<void> test_implicitConst_setLiteral() async {
    await resolveTestCode('''
class A {}

var x = const {A(), ...const {0}, ...{1}};
''');
    await assertHasFix(
      '''
class A {}

var x = {A(), ...const {0}, ...const {1}};
''',
      errorFilter: (e) {
        return e.errorCode == CompileTimeErrorCode.CONST_WITH_NON_CONST;
      },
    );
  }

  Future<void> test_implicitConst_variableDeclarationList() async {
    await resolveTestCode('''
class A {}

const x = A(), y = [0], z = A();
''');
    await assertHasFix(
      '''
class A {}

final x = A(), y = const [0], z = A();
''',
      errorFilter: (e) {
        return e.errorCode == CompileTimeErrorCode.CONST_WITH_NON_CONST &&
            e.offset == testCode.lastIndexOf('A()');
      },
    );
  }

  Future<void> test_implicitConst_variableDeclarationList_typed() async {
    await resolveTestCode('''
class A {}

const Object x = A(), y = [0];
''');
    await assertHasFix(
      '''
class A {}

final Object x = A(), y = const [0];
''',
      errorFilter: (e) {
        return e.errorCode == CompileTimeErrorCode.CONST_WITH_NON_CONST;
      },
    );
  }
}
