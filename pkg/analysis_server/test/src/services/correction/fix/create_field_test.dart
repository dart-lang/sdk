// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreateFieldEnumTest);
    defineReflectiveTests(CreateFieldMixinTest);
    defineReflectiveTests(CreateFieldTest);
  });
}

@reflectiveTest
class CreateFieldEnumTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.createField;

  Future<void> test_initializingFormal_dynamic() async {
    await resolveTestCode('''
enum E {
  one(1), two(2);

  const E(dynamic this.f);
}
''');
    await assertHasFix('''
enum E {
  one(1), two(2);

  final dynamic f;

  const E(dynamic this.f);
}
''');
  }

  Future<void> test_initializingFormal_withoutType() async {
    await resolveTestCode('''
enum E {
  one(1), two(2);

  const E(this.f);
}
''');
    await assertHasFix('''
enum E {
  one(1), two(2);

  final dynamic f;

  const E(this.f);
}
''');
  }

  Future<void> test_initializingFormal_withType() async {
    await resolveTestCode('''
enum E {
  one(1), two(2);

  const E(int this.f);
}
''');
    await assertHasFix('''
enum E {
  one(1), two(2);

  final int f;

  const E(int this.f);
}
''');
  }

  Future<void> test_usedAsGetter() async {
    await resolveTestCode('''
enum E {
  one, two;
}

int f(E e) {
  return e.a;
}
''');
    await assertHasFix('''
enum E {
  one, two;

  final int a;
}

int f(E e) {
  return e.a;
}
''');
  }

  Future<void> test_usedAsGetter_dotShorthand() async {
    await resolveTestCode('''
enum E {
  one, two;
}

E f() {
  return .a;
}
''');
    await assertHasFix('''
enum E {
  one, two;

  static final E a;
}

E f() {
  return .a;
}
''');
  }

  Future<void> test_usedAsSetter() async {
    await resolveTestCode('''
enum E {
  one, two;
}

void f(E e) {
  e.a = 1;
}
''');
    await assertNoFix();
  }
}

@reflectiveTest
class CreateFieldMixinTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.createField;

  Future<void> test_dotShorthand() async {
    await resolveTestCode('''
mixin A {}
void f() {
  A v = .test;
  print(v);
}
''');
    await assertHasFix('''
mixin A {
  static A test;
}
void f() {
  A v = .test;
  print(v);
}
''');
  }

  Future<void> test_getter_qualified_instance() async {
    await resolveTestCode('''
mixin M {
}

void f(M m) {
  int v = m.test;
  print(v);
}
''');
    await assertHasFix('''
mixin M {
  int test;
}

void f(M m) {
  int v = m.test;
  print(v);
}
''');
  }

  Future<void> test_setter_qualified_instance_hasField() async {
    await resolveTestCode('''
mixin M {
  int aaa = 0;
  int zzz = 25;

  existingMethod() {}
}

void f(M m) {
  m.test = 5;
}
''');
    await assertHasFix('''
mixin M {
  int aaa = 0;
  int zzz = 25;

  int test;

  existingMethod() {}
}

void f(M m) {
  m.test = 5;
}
''');
  }
}

@reflectiveTest
class CreateFieldTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.createField;

  Future<void> test_dotShorthand_class() async {
    await resolveTestCode('''
class A {}
void f() {
  A v = .test;
  print(v);
}
''');
    await assertHasFix('''
class A {
  static A test;
}
void f() {
  A v = .test;
  print(v);
}
''');
  }

  Future<void> test_dotShorthand_enum() async {
    await resolveTestCode('''
enum A {
  ONE
}
A f() {
  return .test;
}
''');
    await assertHasFix('''
enum A {
  ONE;

  static final A test;
}
A f() {
  return .test;
}
''');
  }

  Future<void> test_dotShorthand_enum_empty() async {
    await resolveTestCode('''
enum A {}
A f() {
  return .test;
}
''');
    await assertHasFix(
      '''
enum A {;
  static final A test;
}
A f() {
  return .test;
}
''',
      filter: (e) {
        return e.diagnosticCode == diag.dotShorthandUndefinedGetter;
      },
    );
  }

  Future<void> test_dotShorthand_enum_empty_semicolon() async {
    await resolveTestCode('''
enum A {;}
A f() {
  return .test;
}
''');
    await assertHasFix(
      '''
enum A {;
  static final A test;
}
A f() {
  return .test;
}
''',
      filter: (e) {
        return e.diagnosticCode == diag.dotShorthandUndefinedGetter;
      },
    );
  }

  Future<void> test_dotShorthand_extensionType() async {
    await resolveTestCode('''
extension type A(int x) {}
void f() {
  A v = .test;
  print(v);
}
''');
    await assertNoFix();
  }

  Future<void> test_getter_generic() async {
    await resolveTestCode('''
class A {}

T? g<T>(A a) => a.field;
''');
    await assertHasFix('''
class A {
  Object? field;
}

T? g<T>(A a) => a.field;
''');
  }

  Future<void> test_getter_generic_bound() async {
    await resolveTestCode('''
class A {}

T? g<T extends int>(A a) => a.field;
''');
    await assertHasFix('''
class A {
  int? field;
}

T? g<T extends int>(A a) => a.field;
''');
  }

  Future<void> test_getter_generic_class() async {
    await resolveTestCode('''
class A<T> {}

O? g<O>(A<O> a) => a.field;
''');
    await assertHasFix('''
class A<T> {
  T? field;
}

O? g<O>(A<O> a) => a.field;
''');
  }

  Future<void> test_getter_generic_class_unqualified() async {
    await resolveTestCode('''
class A<T> {
  T? m() => field;
}
''');
    await assertHasFix('''
class A<T> {
  T? field;

  T? m() => field;
}
''');
  }

  Future<void> test_getter_generic_lint() async {
    createAnalysisOptionsFile(lints: [LintNames.always_specify_types]);
    await resolveTestCode('''
class A {}

T? g<T extends dynamic>(A a) => a.field;
''');
    await assertHasFix('''
class A {
  dynamic field;
}

T? g<T extends dynamic>(A a) => a.field;
''');
  }

  Future<void> test_getter_generic_noLint() async {
    await resolveTestCode('''
class A {}

T? g<T extends dynamic>(A a) => a.field;
''');
    await assertHasFix('''
class A {
  var field;
}

T? g<T extends dynamic>(A a) => a.field;
''');
  }

  Future<void> test_getter_generics_class_pattern() async {
    await resolveTestCode('''
class A<O> {}

void foo<T extends A<O>, O>(T a) {
  if (a case T(:O field)) {
    print(field);
  }
}
''');
    await assertHasFix('''
class A<O> {
  O field;
}

void foo<T extends A<O>, O>(T a) {
  if (a case T(:O field)) {
    print(field);
  }
}
''');
  }

  Future<void> test_getter_multiLevel() async {
    await resolveTestCode('''
class A {
}
class B {
  A a = A();
}
class C {
  B b = B();
}
void f(C c) {
  int v = c.b.a.test;
  print(v);
}
''');
    await assertHasFix('''
class A {
  int test;
}
class B {
  A a = A();
}
class C {
  B b = B();
}
void f(C c) {
  int v = c.b.a.test;
  print(v);
}
''');
  }

  Future<void> test_getter_qualified_instance() async {
    await resolveTestCode('''
class A {
}
void f(A a) {
  int v = a.test;
  print(v);
}
''');
    await assertHasFix('''
class A {
  int test;
}
void f(A a) {
  int v = a.test;
  print(v);
}
''');
  }

  Future<void> test_getter_qualified_instance_differentLibrary() async {
    newFile('$testPackageLibPath/other.dart', '''
/**
 * A comment to push the offset of the braces for the following class
 * declaration past the end of the content of the test file. Used to catch an
 * index out of bounds exception that occurs when using the test source instead
 * of the target source to compute the location at which to insert the field.
 */
class A {
}
''');

    await resolveTestCode('''
import 'package:test/other.dart';

void f(A a) {
  int v = a.test;
  print(v);
}
''');

    await assertHasFix('''
/**
 * A comment to push the offset of the braces for the following class
 * declaration past the end of the content of the test file. Used to catch an
 * index out of bounds exception that occurs when using the test source instead
 * of the target source to compute the location at which to insert the field.
 */
class A {
  int test;
}
''', target: '$testPackageLibPath/other.dart');
  }

  Future<void> test_getter_qualified_instance_dynamicType() async {
    await resolveTestCode('''
class A {
  B b = B();
  void f(dynamic context) {
    context + b.test;
  }
}
class B {
}
''');
    await assertHasFix('''
class A {
  B b = B();
  void f(dynamic context) {
    context + b.test;
  }
}
class B {
  var test;
}
''');
  }

  Future<void> test_getter_qualified_propagatedType() async {
    await resolveTestCode('''
class A {
  A get self => this;
}
void f() {
  var a = new A();
  int v = a.self.test;
  print(v);
}
''');
    await assertHasFix('''
class A {
  int test;

  A get self => this;
}
void f() {
  var a = new A();
  int v = a.self.test;
  print(v);
}
''');
  }

  Future<void> test_getter_unqualified_instance_asInvocationArgument() async {
    await resolveTestCode('''
class A {
  void m() {
    f(test);
  }
}
f(String s) {}
''');
    await assertHasFix('''
class A {
  String test;

  void m() {
    f(test);
  }
}
f(String s) {}
''');
  }

  Future<void> test_getter_unqualified_instance_assignmentRhs() async {
    await resolveTestCode('''
class A {
  void f() {
    int v = test;
    print(v);
  }
}
''');
    await assertHasFix('''
class A {
  int test;

  void f() {
    int v = test;
    print(v);
  }
}
''');
  }

  Future<void> test_getter_unqualified_instance_asStatement() async {
    await resolveTestCode('''
class A {
  void f() {
    test;
  }
}
''');
    await assertHasFix('''
class A {
  var test;

  void f() {
    test;
  }
}
''');
  }

  Future<void> test_hint() async {
    await resolveTestCode('''
class A {
}
void f(A a) {
  var x = a;
  int v = x.test;
  print(v);
}
''');
    await assertHasFix('''
class A {
  int test;
}
void f(A a) {
  var x = a;
  int v = x.test;
  print(v);
}
''');
  }

  Future<void> test_hint_setter() async {
    await resolveTestCode('''
class A {
}
void f(A a) {
  var x = a;
  x.test = 0;
}
''');
    await assertHasFix('''
class A {
  int test;
}
void f(A a) {
  var x = a;
  x.test = 0;
}
''');
  }

  Future<void> test_ifNull() async {
    await resolveTestCode('''
class A {
  int Function()? _f;
  int Function() get f {
    return _f ?? _defaultF;
  }
}
''');
    await assertHasFix('''
class A {
  int Function()? _f;

  int Function() _defaultF;
  int Function() get f {
    return _f ?? _defaultF;
  }
}
''');
  }

  Future<void> test_importType() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'package:test/a.dart';

A getA() => null;
''');

    await resolveTestCode('''
import 'package:test/b.dart';

class C {
}

void f(C c) {
  c.test = getA();
}
''');

    await assertHasFix('''
import 'package:test/a.dart';
import 'package:test/b.dart';

class C {
  A test;
}

void f(C c) {
  c.test = getA();
}
''');
  }

  Future<void> test_inEnum() async {
    await resolveTestCode('''
enum MyEnum {
  AAA, BBB
}
void f() {
  MyEnum.foo;
}
''');
    await assertNoFix();
  }

  Future<void> test_initializingFormal_functionTyped() async {
    await resolveTestCode('''
class C {
  C(String this.text());
}
''');
    await assertHasFix('''
class C {
  String Function() text;

  C(String this.text());
}
''');
  }

  Future<void> test_initializingFormal_typeVariable() async {
    await resolveTestCode('''
class C<T> {
  C(T this.text);
}
''');
    await assertHasFix('''
class C<T> {
  T text;

  C(T this.text);
}
''');
  }

  Future<void> test_initializingFormal_withDefaultValue() async {
    await resolveTestCode('''
class C {
  C([String this.text = '']);
}
''');
    await assertHasFix('''
class C {
  String text;

  C([String this.text = '']);
}
''');
  }

  Future<void> test_initializingFormal_withType() async {
    await resolveTestCode('''
class C {
  C(String this.text);
}
''');
    await assertHasFix('''
class C {
  String text;

  C(String this.text);
}
''');
  }

  Future<void> test_initializingFormal_withType_constConstuctor() async {
    await resolveTestCode('''
class C {
  const C(String this.text);
}
''');
    await assertHasFix('''
class C {
  final String text;

  const C(String this.text);
}
''');
  }

  Future<void> test_inPart_self() async {
    await resolveTestCode('''
part of 'a.dart';
class A {
}
void f(A a) {
  int v = a.test;
  print(v);
}
''');
    await assertNoFix();
  }

  Future<void> test_inSDK() async {
    await resolveTestCode('''
void f(List p) {
  p.foo = 1;
}
''');
    await assertNoFix();
  }

  Future<void> test_invalidInitializer_withoutType() async {
    await resolveTestCode('''
class C {
  C(this.text);
}
''');
    await assertHasFix('''
class C {
  var text;

  C(this.text);
}
''');
  }

  Future<void> test_objectPattern_explicitName_variablePattern_typed() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case A(test: int y)) {
    y;
  }
}

class A {
}
''');
    await assertHasFix('''
void f(Object? x) {
  if (x case A(test: int y)) {
    y;
  }
}

class A {
  int test;
}
''');
  }

  Future<void> test_objectPattern_explicitName_variablePattern_untyped() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case A(test: var y)) {
    y;
  }
}

class A {
}
''');
    await assertHasFix('''
void f(Object? x) {
  if (x case A(test: var y)) {
    y;
  }
}

class A {
  Object? test;
}
''');
  }

  Future<void> test_objectPattern_explicitName_wildcardPattern_typed() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case A(test: int _)) {}
}

class A {
}
''');
    await assertHasFix('''
void f(Object? x) {
  if (x case A(test: int _)) {}
}

class A {
  int test;
}
''');
  }

  Future<void> test_objectPattern_implicitName_variablePattern_typed() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case A(:int test)) {
    test;
  }
}

class A {
}
''');
    await assertHasFix('''
void f(Object? x) {
  if (x case A(:int test)) {
    test;
  }
}

class A {
  int test;
}
''');
  }

  Future<void> test_setter_generic_BAD() async {
    await resolveTestCode('''
class A {
}
class B<T> {
  List<T> items = [];
  void f(A a) {
    a.test = items;
  }
}
''');
    await assertHasFix('''
class A {
  List<Object?> test;
}
class B<T> {
  List<T> items = [];
  void f(A a) {
    a.test = items;
  }
}
''');
  }

  Future<void> test_setter_generic_OK_local() async {
    await resolveTestCode('''
class A<T> {
  List<T> items = [];

  void f(A a) {
    test = items;
  }
}
''');
    await assertHasFix('''
class A<T> {
  List<T> items = [];

  List<T> test;

  void f(A a) {
    test = items;
  }
}
''');
  }

  Future<void> test_setter_qualified_instance_hasField() async {
    await resolveTestCode('''
class A {
  int aaa = 0;
  int zzz = 25;

  existingMethod() {}
}
void f(A a) {
  a.test = 5;
}
''');
    await assertHasFix('''
class A {
  int aaa = 0;
  int zzz = 25;

  int test;

  existingMethod() {}
}
void f(A a) {
  a.test = 5;
}
''');
  }

  Future<void> test_setter_qualified_instance_hasMethod() async {
    await resolveTestCode('''
class A {
  existingMethod() {}
}
void f(A a) {
  a.test = 5;
}
''');
    await assertHasFix('''
class A {
  int test;

  existingMethod() {}
}
void f(A a) {
  a.test = 5;
}
''');
  }

  Future<void> test_setter_qualified_static() async {
    await resolveTestCode('''
class A {
}
void f() {
  A.test = 5;
}
''');
    await assertHasFix('''
class A {
  static int test;
}
void f() {
  A.test = 5;
}
''');
  }

  Future<void> test_setter_unqualified_instance() async {
    await resolveTestCode('''
class A {
  void f() {
    test = 5;
  }
}
''');
    await assertHasFix('''
class A {
  int test;

  void f() {
    test = 5;
  }
}
''');
  }

  Future<void> test_setter_unqualified_static() async {
    await resolveTestCode('''
class A {
  static void f() {
    test = 5;
  }
}
''');
    await assertHasFix('''
class A {
  static int test;

  static void f() {
    test = 5;
  }
}
''');
  }

  Future<void> test_switchExpression_expression() async {
    await resolveTestCode('''
class A {
  void f() {
    int _ = switch (test) {
      _ => 0,
    };
  }
}
''');
    await assertHasFix('''
class A {
  Object? test;

  void f() {
    int _ = switch (test) {
      _ => 0,
    };
  }
}
''');
  }

  Future<void> test_switchExpression_result() async {
    await resolveTestCode('''
class A {
  void f(int value) {
    int _ = switch (value) {
      _ => test,
    };
  }
}
''');
    await assertHasFix('''
class A {
  int test;

  void f(int value) {
    int _ = switch (value) {
      _ => test,
    };
  }
}
''');
  }
}
